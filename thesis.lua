-- https://github.com/jgm/pandoc/releases/download/3.11/pandoc-3.11-1-amd64.deb
if PANDOC_VERSION < pandoc.types.Version '3.11' then
  error('Pandoc 3.11 or higher is required (found ' .. tostring(PANDOC_VERSION) .. ')')
end

-- Pandoc 3.x Lua filter and custom Typst writer for the accompanying reader.
-- Input classes: Figure.marginfigure / Figure.subfigure; Span.sidenote / Span.marginnote
-- wrapping exactly one Note. Requires haobook in the Typst document scope.

-- Escape text for use inside a Typst string literal.
local function typst_string(s)
  s = s:gsub('\\', '\\\\'):gsub('"', '\\"'):gsub('%s*\n%s*', ' ')
  return '"' .. s .. '"'
end

-- Parse \evilEdgeCase{a}{b}; returns Typst call text or nil.
local function evil_edge_case(text)
  local a, b = text:match('^\\evilEdgeCase%s*(%b{})%s*(%b{})%s*$')
  if not a then return nil end
  return '#evil-edge-case(' .. typst_string(a:sub(2, -2)) .. ', '
    .. typst_string(b:sub(2, -2)) .. ')'
end

local function caption_is_empty(caption)
  return caption ~= nil
     and pandoc.utils.stringify(caption.long) == ''
     and #caption.long <= 1
end

local function author_cites(cite)
  local out, changed = pandoc.Inlines{}, false
  for _, c in ipairs(cite.citations) do
    if #out > 0 then out:insert(pandoc.Space()) end
    if c.mode == 'AuthorInText' then
      changed = true
      out:insert(pandoc.RawInline('typst',
        '#cite(<' .. c.id .. '>, form: "author")#h(0pt)')) -- hack to prevent merging citations
    else
      out:insert(pandoc.Cite(cite.content, {c}))
    end
  end
  if changed then return out end
end

local function transform(doc, opts)
  doc = doc:walk {
    RawInline = function(raw)
      if raw.format == 'latex' or raw.format == 'tex' then
        local call = evil_edge_case(raw.text)
        if call then return pandoc.RawInline('typst', call) end
      end
    end,
    RawBlock = function(raw)
      if raw.format == 'latex' or raw.format == 'tex' then
        local call = evil_edge_case(raw.text)
        if call then return pandoc.RawBlock('typst', call) end
      end
    end,
  }

  -- Validate before rendering any fragments: otherwise unsupported TeX in a
  -- note or caption could disappear inside a generated raw Typst element.
  local function reject_raw_tex(raw)
    if raw.format == 'latex' or raw.format == 'tex' then
      error('Unhandled raw LaTeX (' .. raw.t .. '):\n' .. raw.text, 0)
    end
  end
  doc:walk { RawInline = reject_raw_tex, RawBlock = reject_raw_tex }

  -- Use fresh options so a standalone template is never applied to fragments.
  local fragment_opts = pandoc.WriterOptions {
    columns = opts.columns,
    wrap_text = opts.wrap_text,
    dpi = opts.dpi,
    identifier_prefix = opts.identifier_prefix,
  }

  local function render(blocks)
    return pandoc.write(pandoc.Pandoc(blocks), 'typst', fragment_opts)
      :gsub('%s+$', '')
  end

  local function indent(text)
    return '  ' .. text:gsub('\n', '\n  ')
  end

  local custom_colors = {
    mygreen = 'rgb(38, 162, 105)',
  }

  -- Convert layout markers before rendering notes or figure fragments,
  -- and map the LaTeX project's images/ directory to the Typst assets directory.
  doc = doc:walk {
    Cite = author_cites,
    Span = function(span)
      if #span.content == 0 and span.classes:includes('pagebreak') then
        return pandoc.RawInline('typst', '#pagebreak()')
      end

      local label = span.attributes['acronym-label']
      if label then
        -- spaces -> dashes (parentheses drop gsub's second return value)
        label = (label:gsub('%s+', '-'))

        local form = span.attributes['acronym-form'] or ''

        local suffix = ''
        if form:find('plural') then
          suffix = ':pl'
        elseif form:find('long') then
          suffix = ':long'
        end

        return pandoc.RawInline('typst', '@' .. label .. suffix)
      end

      local style = span.attributes['style']
      if style then
        -- wrap in ';' so `background-color` is not matched by accident
        local name = (';' .. style .. ';'):match(';%s*color%s*:%s*(%a+)%s*;')
        if name then
          name = name:lower()
          local fill = custom_colors[name] or name
          local out = pandoc.List{
            pandoc.RawInline('typst', '#text(fill: ' .. fill .. ')[')
          }
          out:extend(span.content)
          out:insert(pandoc.RawInline('typst', ']'))
          return out
        end
      end
    end,
    Div = function(div)
      if #div.content == 0 and div.classes:includes('pagebreak') then
        return pandoc.RawBlock('typst', '#pagebreak()')
      end
    end,
    Image = function(img)
      if img.src:match('^%.%./text%-rdt/target/pdfs/') then
        img.src = '/result/' .. img.src:sub(25)
        return img
      end
      if img.src:match('^figures/') then
        img.src = '/' .. img.src
        return img
      end
    end
  }

  doc = doc:walk {
    Span = function(span)
      local command
      if span.classes:includes('marginnote') then
        command = 'margin-note'
      elseif span.classes:includes('sidenote') then
        command = 'side-note'
      else
        return
      end
      if #span.content ~= 1 or span.content[1].t ~= 'Note' then
        error(command .. ' requires a Span containing exactly one Note')
      end
      return pandoc.RawInline('typst',
        '#haobook.' .. command .. '[' .. render(span.content[1].content) .. ']')
    end,

    Figure = function(fig)
      local figure_options = ''
      if fig.classes:includes('subfigure') then
        figure_options = 'kind: "subfigure",'
      elseif fig.classes:includes('minipage') then
        figure_options = 'kind: "minpage", supplement: none,'
      end

      if fig.classes:includes('grid') then
        local cells = {}
        for _, b in ipairs(fig.content) do
          if b.t == 'Figure' or (b.t == 'RawBlock' and b.format == 'typst') then
            cells[#cells + 1] = '      [' .. render({ b }) .. '],'
          end
        end
        local label = ''
        if fig.identifier ~= '' then
          label = ' <' .. (opts.identifier_prefix or '') .. fig.identifier .. '>'
        end
        local caption_line = ''
        if not caption_is_empty(fig.caption) then
          caption_line = '  caption: [' .. render(fig.caption.long) .. '],\n'
        end
        return pandoc.RawBlock('typst',
          '#figure(' .. figure_options .. '\n'
            .. '  {\n'
            .. '    show figure: set align(bottom)\n'
            .. '    grid(\n'
            .. '      columns: ' .. #cells .. ',\n'
            .. '      align: bottom,\n'
            .. table.concat(cells, '\n') .. '\n'
            .. '    )\n'
            .. '  },\n'
            .. caption_line
            .. ')' .. label)
      end

      if figure_options ~= '' then
        local rendered = render({ fig })
        assert(rendered:match('^#figure%('), 'Unexpected Typst figure output')
        return pandoc.RawBlock('typst',
          (rendered:gsub('^#figure%(', '#figure(' .. figure_options, 1)))
      end

      if not fig.classes:includes('marginfigure') then return end

      local label_argument = ''
      if fig.identifier ~= '' then
        -- Construct the label programmatically using any prefix in options
        local label_id = (opts.identifier_prefix or '') .. fig.identifier
        label_argument = '  label: <' .. label_id .. '>,\n'
        -- Clear identifier so Pandoc renders the figure without a trailing label
        fig.identifier = ''
      end

      local rendered = render({ fig })

      -- In a function argument, figure(...) is already in code mode.
      assert(rendered:match('^#figure%('), 'Unexpected Typst figure output')
      return pandoc.RawBlock('typst',
        '#haobook.side-figure(\n' .. indent(rendered:sub(2)) .. ',\n'
          .. label_argument .. ')')
    end
  }

  doc = doc:walk {
    Note = function(note)
      local labels = {}
      local content = note.content:walk {
        Span = function(span)
          if span.identifier ~= '' and #span.content == 0 then
            labels[#labels + 1] = ' <' .. (opts.identifier_prefix or '')
              .. span.identifier .. '>'
            return {}
          end
        end
      }
      if #labels > 0 then
        return pandoc.RawInline('typst',
          '#footnote[' .. render(content) .. ']' .. table.concat(labels))
      end
    end
  }

  return doc
end

-- Entry point when used with --lua-filter haobook.lua -t typst.
function Pandoc(doc)
  return transform(doc, PANDOC_WRITER_OPTIONS)
end

-- Entry point when used with -t haobook.lua.
function Writer(doc, opts)
  return pandoc.write(transform(doc, opts), 'typst', opts)
end

Template = pandoc.template.default('typst')
