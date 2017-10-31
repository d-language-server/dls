module dls.protocol.configuration;

class Configuration
{
    FormatterConfiguration formatter;
}

class FormatterConfiguration
{
    static enum BraceStyle
    {
        allman = "allman",
        otbs = "tobs",
        stroustrup = "stroustrup"
    }

    static enum EndOfLine
    {
        lf = "lf",
        cr = "cr",
        crlf = "crlf"
    }

    bool alignSwitchStatements = true;
    BraceStyle braceStyle = BraceStyle.allman;
    EndOfLine endOfLine = EndOfLine.lf;
    size_t softMaxLineLength = 80;
    size_t maxLineLength = 120;
    bool outdentAttributes = true;
    bool spaceAfterCast = true;
    bool selectiveImportSpace = true;
    bool splitOperatorAtLineEnd = false;
    bool compactLabeledStatements = true;
}
