module dls.protocol.interfaces.dls;

import dls.util.constants : Tr;

class TranslationParams
{
    string tr;

    this(Tr tr = Tr._)
    {
        static import dls.util.i18n;

        this.tr = dls.util.i18n.tr(tr);
    }
}

class DlsUpgradeSizeParams : TranslationParams
{
    size_t size;

    this(Tr tr = Tr._, size_t size = size_t.init)
    {
        super(tr);
        this.size = size;
    }
}
