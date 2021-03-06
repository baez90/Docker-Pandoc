FROM alpine:latest as build

RUN apk add --update \
        texlive-full \
        texmf-dist \
        ghostscript \
        librsvg \
        ttf-dejavu \
        libarchive-tools \
        make \
        git

WORKDIR /tmp/packages/tex

RUN wget -qO- http://ctan.mirrors.hoobly.com/macros/latex/contrib/csquotes.zip | bsdtar -xvf -
RUN wget -qO- http://ctan.mirrors.hoobly.com/macros/latex/contrib/mdframed.zip | bsdtar -xvf -
RUN wget -qO- http://ctan.mirrors.hoobly.com/macros/latex/contrib/makecmds.zip | bsdtar -xvf -
RUN wget -qO- http://ctan.mirrors.hoobly.com/macros/latex/contrib/filecontents.zip | bsdtar -xvf -
RUN wget -qO- http://ctan.mirrors.hoobly.com/macros/latex/contrib/needspace.zip | bsdtar -xvf -
RUN wget -qO- http://ctan.mirrors.hoobly.com/macros/latex/contrib/titlesec.zip | bsdtar -xvf -
RUN wget -qO- http://ctan.mirrors.hoobly.com/macros/latex/contrib/titling.zip | bsdtar -xvf -
RUN wget -qO- http://mirrors.ctan.org/fonts/psfonts/ly1.zip | bsdtar -xvf -
RUN wget http://mirrors.ctan.org/macros/latex/contrib/etoolbox/etoolbox.sty
RUN wget http://ctan.mirrors.hoobly.com/macros/latex/contrib/mweights/mweights.sty

RUN git clone https://github.com/silkeh/latex-sourcesanspro.git /tmp/sourcesanspro && \
    rm -rf /tmp/sourcesanspro/doc /tmp/sourcesanspro/.git && \
    mv /tmp/sourcesanspro/tex/* /tmp/packages/tex/ && \
    mv /tmp/sourcesanspro/fonts /tmp/packages/

WORKDIR /tmp

RUN wget -qO- http://mirrors.ctan.org/fonts/sourcecodepro.zip | bsdtar -xvf - && \
    mv sourcecodepro/tex/* /tmp/packages/tex && \
    mkdir -p /tmp/packages/fonts/tfm/sourcecodepro && \
    mkdir -p /tmp/packages/fonts/enc/dvips/sourcecodepro && \
    mkdir -p /tmp/packages/fonts/map/dvips/sourcecodepro && \
    mkdir -p /tmp/packages/fonts/opentype/sourcecodepro && \
    mkdir -p /tmp/packages/fonts/type1/sourcecodepro && \
    mkdir -p /tmp/packages/fonts/vf/sourcecodepro && \
    mv sourcecodepro/fonts/SourceCodePro*.tfm /tmp/packages/fonts/tfm/sourcecodepro && \
    mv sourcecodepro/fonts/*.enc /tmp/packages/fonts/enc/dvips/sourcecodepro && \
    mv sourcecodepro/fonts/SourceCodePro.map /tmp/packages/fonts/map/dvips/sourcecodepro && \
    mv sourcecodepro/fonts/SourceCodePro*.otf /tmp/packages/fonts/opentype/sourcecodepro && \
    mv sourcecodepro/fonts/SourceCodePro*.pfb /tmp/packages/fonts/type1/sourcecodepro && \
    mv sourcecodepro/fonts/SourceCodePro*.vf /tmp/packages/fonts/vf/sourcecodepro && \
    cd /tmp/packages/tex/makecmds/ && \
    latex makecmds.ins && \
    cd /tmp/packages/tex/mdframed/ && \
    make all && \
    cd /tmp/packages/tex/filecontents && \
    latex filecontents.ins && \
    cd /tmp/packages/tex/titling && \
    latex titling.ins

FROM alpine:3.11

ARG BUILD_DATE
ARG VCS_REF

ARG PANDOC_VERSION="2.9.2"

LABEL org.label-schema.build-date=$BUILD_DATE \
      org.label-schema.name="Pandoc" \
      org.label-schema.description="Pandoc container including PDFLaTeX to build PDFs from Markdown" \
      org.label-schema.url="https://github.com/kns-it/Docker-Pandoc" \
      org.label-schema.vcs-ref=$VCS_REF \
      org.label-schema.vcs-url="https://github.com/kns-it/Docker-Pandoc" \
      org.label-schema.vendor="KNS" \
      org.label-schema.version=$PANDOC_VERSION \
      org.label-schema.schema-version="1.0" \
      maintainer="sebastian.kurfer@kns-it.de"

COPY --from=build /tmp/packages /usr/share/texmf-var

RUN apk add \
            --update \
            --no-cache \
            texlive-full \
            texmf-dist \
            ghostscript \
            librsvg \
            ttf-dejavu \
            make \
            git && \
    rm -rf /var/cache/apk/* && \
    wget -O - https://github.com/jgm/pandoc/releases/download/${PANDOC_VERSION}/pandoc-${PANDOC_VERSION}-linux-amd64.tar.gz | tar xvz -C /tmp/ --exclude "**/share/**" && \
    mv /tmp/pandoc-${PANDOC_VERSION}/bin/* /usr/bin/ && \
    rm -rf /tmp/* && \
    adduser pandoc -D -s /bin/sh && \
    texhash /usr/share/texmf-var && \
    cd /usr/share/texmf-var/tex/needspace && \
    pdflatex needspace.tex && \
    mktexlsr && \
    texhash /usr/share/texmf-var

CMD [ "/bin/sh" ]

USER pandoc
WORKDIR /home/pandoc
