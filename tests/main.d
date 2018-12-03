/*
 *Copyright (C) 2018 Laurent Tréguier
 *
 *This file is part of DLS.
 *
 *DLS is free software: you can redistribute it and/or modify
 *it under the terms of the GNU General Public License as published by
 *the Free Software Foundation, either version 3 of the License, or
 *(at your option) any later version.
 *
 *DLS is distributed in the hope that it will be useful,
 *but WITHOUT ANY WARRANTY; without even the implied warranty of
 *MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *GNU General Public License for more details.
 *
 *You should have received a copy of the GNU General Public License
 *along with DLS.  If not, see <http://www.gnu.org/licenses/>.
 *
 */

import dls.util.communicator : Communicator;
import std.json : JSONValue;

private immutable orderFileName = "_order";

private enum MessageFileType : string
{
    order = ".txt",
    input = ".in.json",
    output = ".out.json",
    reference = ".ref.json"
}

private struct Message
{
    private string name;
    private char[] content;
}

private class TestCommunicator : Communicator
{
    string[] testedDirectories;
    private Message[][string] _directoriesMessages;
    private string _directory;
    private string _lastDirectory;
    private string _lastReadMessageName;
    private string _currentOutput;
    private JSONValue[] _outputMessages;

    this()
    {
        import std.algorithm : filter;
        import std.file : SpanMode, dirEntries, getcwd, isDir;
        import std.path : buildPath;

        foreach (directory; dirEntries(buildPath(getcwd(), "tests"), SpanMode.shallow).filter!(
                entry => isDir(entry.name) && hasMessages(entry.name)))
        {
            _directoriesMessages[directory] = [];

            if (_directory.length == 0)
            {
                _directory = directory;
            }
        }

        fillDirectoryMessages();
    }

    bool hasData()
    {
        return _directoriesMessages.keys.length > 0;
    }

    char[] read(size_t size)
    {
        auto currentMessage = _directoriesMessages[_directory][0];
        auto result = currentMessage.content[0 .. size];

        if (currentMessage.content.length > size)
        {
            _directoriesMessages[_directory][0].content = currentMessage.content[size .. $];
        }
        else
        {
            _lastDirectory = _directory;
            _lastReadMessageName = currentMessage.name;
            _outputMessages = [];

            if (_directoriesMessages[_directory].length > 1)
            {
                _directoriesMessages[_directory] = _directoriesMessages[_directory][1 .. $];
            }
            else
            {
                testedDirectories ~= _directory;
                _directoriesMessages.remove(_directory);

                if (_directoriesMessages.keys.length > 0)
                {
                    _directory = _directoriesMessages.keys[0];
                    fillDirectoryMessages();
                }
            }
        }

        return result;
    }

    void write(const char[] buffer)
    {
        _currentOutput ~= buffer;
    }

    void flush()
    {
        import std.algorithm : findSkip;
        import std.file : write;
        import std.json : JSONOptions, parseJSON;

        _currentOutput.findSkip("\r\n\r\n");
        _outputMessages ~= parseJSON(_currentOutput);
        const outputPath = getMessagePath(_lastDirectory, _lastReadMessageName,
                MessageFileType.output);
        write(outputPath, JSONValue(_outputMessages)
                .toPrettyString(JSONOptions.doNotEscapeSlashes));
        _currentOutput = "";
    }

    private void fillDirectoryMessages()
    {
        import std.file : readText;
        import std.format : format;

        foreach (line; getOrderedMessageNames(_directory))
        {
            const inputPath = getMessagePath(_directory, line, MessageFileType.input);
            auto input = readText!(char[])(inputPath).expandTestUris(_directory);
            auto message = Message(line);
            message.content ~= format("Content-Length: %s\r\n\r\n%s", input.length, input);
            _directoriesMessages[_directory] ~= message;
        }
    }
}

int main()
{
    import dls.server : Server;
    import dls.util.communicator : communicator;

    auto testCommunicator = new TestCommunicator();
    communicator = testCommunicator;
    Server.loop();
    return checkResults(testCommunicator.testedDirectories);
}

private int checkResults(const string[] directories)
{
    import std.algorithm : reduce;
    import std.array : array;
    import std.format : format;
    import std.json : JSONOptions;
    import std.range : repeat;
    import std.stdio : stderr;

    static void writeHeader(const string header)
    {
        auto headerLine = repeat('=', header.length);
        stderr.writeln(headerLine);
        stderr.writeln(header);
        stderr.writeln(headerLine);
    }

    size_t testCount;
    size_t passCount;

    foreach (directory; directories)
    {
        writeHeader(format("Test directory %s", directory));

        auto orderedMessageNames = getOrderedMessageNames(directory).array;
        const maxNameLength = reduce!((a, b) => a.length > b.length ? a : b)("",
                orderedMessageNames).length;

        foreach (name; orderedMessageNames)
        {
            auto output = getJSON(directory, name, MessageFileType.output);
            auto reference = getJSON(directory, name, MessageFileType.reference);
            stderr.writef(" * Message %s%s: ", name, repeat(' ', maxNameLength - name.length));
            ++testCount;

            if (output != reference)
            {
                stderr.writeln("FAIL \u2718");
                writeDiff(reference.toPrettyString(JSONOptions.doNotEscapeSlashes),
                        output.toPrettyString(JSONOptions.doNotEscapeSlashes));
            }
            else
            {
                stderr.writeln("PASS \u2714");
                ++passCount;
            }
        }
    }

    writeHeader(format("Passed message tests: %s/%s", passCount, testCount));
    return passCount == testCount ? 0 : 1;
}

private bool hasMessages(const string directory)
{
    import std.file : exists;

    return exists(getMessagePath(directory, orderFileName, MessageFileType.order));
}

private auto getOrderedMessageNames(const string directory)
{
    import std.algorithm : map;
    import std.stdio : File;
    import std.string : strip;

    return File(getMessagePath(directory, orderFileName, MessageFileType.order), "r")
        .byLineCopy.map!strip;
}

private JSONValue getJSON(const string directory, const string name, const MessageFileType type)
{
    import std.algorithm : sort;
    import std.array : array;
    import std.json : JSONValue, parseJSON;
    import std.file : exists, readText;

    const path = getMessagePath(directory, name, type);
    auto rawJSON = parseJSON(exists(path) ? readText(path).expandTestUris(directory) : "[]");
    return JSONValue(rawJSON.array.sort!((a, b) => a.toString() < b.toString()).array);
}

private string getMessagePath(const string directory, const string name, const MessageFileType type)
{
    import std.path : buildPath;

    return buildPath(directory, "messages", name ~ type);
}

private inout(char[]) expandTestUris(inout(char[]) text, const string directory)
{
    import dls.util.uri : Uri;
    import std.array : replace;

    return text.replace("testFile://", Uri.fromPath(directory).toString());
}

private void writeDiff(const string reference, const string output)
{
    import std.conv : to;
    import std.file : remove, tempDir, write;
    import std.path : buildPath;
    import std.process : Config, execute;
    import std.stdio : stderr;
    import std.uuid : randomUUID;

    const mainPath = buildPath(tempDir, randomUUID().toString());
    const refPath = mainPath ~ MessageFileType.reference;
    const outPath = mainPath ~ MessageFileType.output;

    write(refPath, reference);
    write(outPath, output);

    scope (exit)
    {
        remove(refPath);
        remove(outPath);
    }

    version (Windows)
    {
        const args = ["fc.exe", refPath, outPath];
    }
    else version (Posix)
    {
        const args = ["diff", "-U", size_t.max.to!string, refPath, outPath];
    }
    else
    {
        string[] args;
    }

    stderr.write(args.length > 0 ? execute(args, null, Config.suppressConsole)
            .output : "No diff output available on this platform\n");
}
