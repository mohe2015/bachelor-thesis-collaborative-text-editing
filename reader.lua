-- https://github.com/jgm/pandoc/releases/download/3.11/pandoc-3.11-1-amd64.deb
if PANDOC_VERSION < pandoc.types.Version '3.11' then
  error('Pandoc 3.11 or higher is required (found ' .. tostring(PANDOC_VERSION) .. ')')
end

local definitions = [=[
\newcommand{\sidenote}[1][]{\sidenoteB}
\newcommand{\sidenoteB}[1][]{\sidenoteC}
\newcommand{\sidenoteC}[1]{\footnote{\pandocnotekind{sidenote}\par #1}}

\newcommand{\marginnote}[1][]{\marginnoteB}
\newcommand{\marginnoteB}[1][]{\marginnoteC}
\newcommand{\marginnoteC}[1]{\footnote{\pandocnotekind{marginnote}\par #1}}

\newcommand{\marginfigure}[1][]{\marginfigureB}
\newcommand{\marginfigureB}[1][]{\begin{figure}\pandocmargin{}\par}
\newcommand{\endmarginfigure}{\end{figure}}

\newcommand{\makebox}[1][]{\makeboxB}
\newcommand{\makeboxB}[1][]{\makeboxC}
\newcommand{\makeboxC}[1]{#1}

\newcommand{\addcontentsline}[3][]{\par #3}

\newcommand{\labsec}[1]{\label{#1}}
\newcommand{\labfig}[1]{\label{#1}}
\newcommand{\Cref}[1]{\ref{#1}}

\def\Citeauthor*#1{\cite{#1}}

\newcommand{\footref}[1]{\ref{#1}}
\newcommand{\index}[1]{}
\newcommand{\setchapterpreamble}[2][]{}
\newcommand{\pagebreak}{\pandocpagebreak{}}
\newcommand{\clearpage}{\pandocpagebreak{}}
\newcommand{\cleardoublepage}{\pandocpagebreak{}}
\newcommand{\vfill}{}
\newcommand{\large}{}
\newcommand{\newpage}{}
\newcommand{\noindent}{}
\renewcommand{\vspace}[1]{}
\newcommand{\hspace}[1]{}
\newcommand{\pagelayout}[1]{}
\newenvironment{multicols}[1]{}{}
\newcommand{\bgroup}{}
\newcommand{\egroup}{}
\newcommand{\KOMAoptions}{}
\newcommand{\protect}{}
\newcommand{\mbox}[1]{\par #1}
\newcommand{\glsfmttext}[1]{#1}
\newcommand{\S}{\text{§}}
\newenvironment{flushright}{}{}

\newcommand{\listing}{\begin{figure}}
\newcommand{\endlisting}{\end{figure}}


\renewenvironment{abstract}[1][]{}{}

\newcommand{\addtocontents}{}

\newcommand{\twoMinipageFigures}[4]{
  \begin{figure}
    \includegraphics{#1}
    #2
  \end{figure}
  \begin{figure}
    \includegraphics{#3}
    #4
  \end{figure}
}

\newcommand{\benchmarkResults}[2]{
    \begin{figure}
        \begin{subfigure}{.5\textwidth}
            \includegraphics[width=\textwidth]{../text-rdt/jvm/figure-benchmark-results/#1.pdf}
            \caption{time}
            \label{fig:#1-time}
        \end{subfigure}%
        \begin{subfigure}{.5\textwidth}
            \includegraphics[width=\textwidth]{../text-rdt/jvm/figure-benchmark-results/#1-memory.pdf}
            \caption{memory}
            \label{fig:#1-memory}
        \end{subfigure}
        \caption{#2}
        \label{fig:#1}
    \end{figure}
}

]=]

local function marker_text(block)
  if block and block.t == 'Para' and #block.content == 1 then
    block = block.content[1]
  end
  if block
      and (block.t == 'RawBlock' or block.t == 'RawInline')
      and block.format == 'latex' then
    return block.text
  end
end

function Reader(input, opts)
  return pandoc.read(definitions .. tostring(input),
    'latex+latex_macros+raw_tex', opts):walk {
    RawInline = function(raw)
      if raw.format == 'latex' then
        if marker_text(raw) == '\\pandocpagebreak{}' then
          return pandoc.Span({}, pandoc.Attr('', { 'pagebreak' }))
        end

        local target = raw.text:match('^\\ref%s*%{([^}]+)%}')
        if target then
          local citation = pandoc.Citation(target, 'NormalCitation')
          return pandoc.Cite({ pandoc.Str('@' .. target) }, { citation })
        end

        -- Convert standalone \label{...} outside figures into an empty Span anchor
        local label = raw.text:match('^\\label%s*%{([^}]+)%}')
        if label then
          return pandoc.Span({}, pandoc.Attr(label, {}, {}))
        end
      end
    end,

    RawBlock = function(raw)
      if raw.format == 'latex' then
        if marker_text(raw) == '\\pandocpagebreak{}' then
          return pandoc.Div({}, pandoc.Attr('', { 'pagebreak' }))
        end
      end
    end,

    Figure = function(fig)
      if marker_text(fig.content[1]) == '\\pandocmargin{}' then
        fig.content:remove(1)
        fig.classes:insert('marginfigure')
      end

      -- Walk fig.content so fig.identifier mutations persist
      fig.content = fig.content:walk {
        Span = function(span)
          if span.identifier ~= '' and #span.content == 0 then
            if fig.identifier == '' then
              fig.identifier = span.identifier
            end
            return {}
          end
        end,
        SoftBreak = function()
          return {} -- Remove SoftBreak nodes from the figure AST
        end
      }

      -- A Figure needs block content, so retain Plain around inline images.
      -- Drop LaTeX-only centering, which obscures the single-image structure.
      fig.content = fig.content:filter(function(block)
        return not (block.t == 'RawBlock' and block.format == 'latex'
          and block.text:match('^%s*\\centering%s*$'))
      end)
      return fig
    end,

    Note = function(note)
      local text = marker_text(note.content[1])
      local kind = text and text:match('^\\pandocnotekind{(%a+)}$')
      if kind == 'sidenote' or kind == 'marginnote' then
        note.content:remove(1)
        return pandoc.Span({ note }, pandoc.Attr('', { kind }))
      end
    end
  }
end
