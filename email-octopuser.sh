#!/usr/bin/env bash

if [[ -z "$1" ]] || [[ ! -f "$1" ]]; then
	echo "$1 is not a file" >&2
	exit 1
fi

# Build a table of contents from every h1/h2/h3 that carries an id.
# Entries are indented relative to the shallowest heading level found.
TOC=$(awk '/<article>/,/<\/article>/' "$1" | awk '
	{ doc = doc $0 "\n" }
	END {
		n = 0
		min = 9
		while (match(doc, /<h[1-3][^>]*>/)) {
			tag = substr(doc, RSTART, RLENGTH)
			level = substr(tag, 3, 1)
			doc = substr(doc, RSTART + RLENGTH)
			close_at = index(doc, "</h" level ">")
			if (close_at == 0) continue
			if (!match(tag, /[ \t\n]id="[^"]+"/)) continue
			n++
			ids[n] = substr(tag, RSTART + 5, RLENGTH - 6)
			text = substr(doc, 1, close_at - 1)
			gsub(/<[^>]*>/, "", text)
			gsub(/[ \t\n]+/, " ", text)
			gsub(/^ | $/, "", text)
			texts[n] = text
			levels[n] = level
			if (level < min) min = level
		}
		if (n == 0) exit
		print "    <nav style=\"margin-block: 1em; padding: 0.8em 1em; background: #f5f6fa; border-radius: 12px;\">"
		print "      <p style=\"margin: 0 0 0.4em; font-weight: 600;\">Contents</p>"
		print "      <ul style=\"margin: 0; padding-left: 1.2em;\">"
		for (i = 1; i <= n; i++) {
			indent = (levels[i] - min) * 1.5
			print "        <li style=\"margin-left: " indent "em;\"><a href=\"#" ids[i] "\">" texts[i] "</a></li>"
		}
		print "      </ul>"
		print "    </nav>"
	}
')
export TOC


awk '/<article>/,/<\/article>/' "$1" | sed 's/href="\//href="https:\/\/playtechnique.io\//' | \
sed 's/src="\//src="https:\/\/playtechnique.io\//' | \
sed 's/class="attribution"/class="attribution" style="margin-inline:2.5em; font-weight:400; font-size: 0.9em"/' | \
sed 's|<blockquote>|<blockquote style="margin-inline: 2.5em; font-size:1.1em; background: #eaeefa; border-radius: 16px; padding: 0.8em;"><span style="color:#ccc; font-size:1.8em; line-height:0; vertical-align:-0.2em;">\&ldquo;</span>|' | \
sed 's|<code>|<code style="background-color: light-dark(black, white); font-color:light-dark(white, black)|' | \
sed "/<article>/a\\
    <p style=\"font-size: 0.8em;\">\\ to view this email as a bookmarkable webpage, click <a href=\"${URL}\">here</a>.\\
    </p>" | \
awk '
	{ print }
	/<article>/ { in_header = 1 }
	in_header && /<\/p>/ { if (ENVIRON["TOC"] != "") print ENVIRON["TOC"]; in_header = 0 }
'
echo "From: Gwyn James - PlayTechnique" >&2
echo "Sending From: newsletter@playtechnique.io" >&2
echo "Preview line: \"Title of the Paper\" by Author" >&2
