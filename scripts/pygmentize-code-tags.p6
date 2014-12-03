#!/usr/bin/env perl6

# Syntax-highlight Perl 6 (and other) source code snippets inside HTML files.
# 
# Usage:
#    ./pygmentize-code-tags.p6 input.htm > output.htm
#    cat input.htm | ./pygmentize-code-tags.p6 > output.htm
# 
# "Syntax highlights" the contents of any <code>...</code> elements in an HTML
# file, by adding span tags (with class attributes) around syntactical tokens.
# 
# By default, the text is highlighted as if it were Perl 6 source code; Other
# lexers can be selected on a per-element basis by setting the 'rel' attribute,
# e.g. <code rel="python">...</code>. See `pygmentize -L lexers` for a list of
# allowed names.
# 
# In order to actually see any highlighting, you will have to manually add a
# CSS stylesheet which defines colors/formats for the added spans. You can get
# a usable preset stylesheet by running:
#     pygmentize -S fruity -f html -a '.syntax'
# (^ or replace 'fruity' with any style name listed by `pygmentize -L styles`)
# 
# This script tries its best to deal with malformed HTML without breaking
# anything (and since it skips <code> elements which already contain other HTML
# tags, it should even be idempotent). But no warranties... :)
# 
# Dependencies:
#   - a Perl 6 interpreter (Rakudo+Moar recommended)
#   - the 'HTML::Entity' Perl 6 module (https://github.com/Mouq/HTML-Entity/)
#   - Pygments ('python-pygments' package on Debian-based distros)
#
###############################################################################

use HTML::Entity;
grammar HtmlWithCode {...};

#------ Main code ------#

my $source = slurp;

for HtmlWithCode.parse($source)<code>.reverse {
    
    my $line = (1 + .prematch.comb(/\n/));
    my %attr = .<attr>.map({ ~.<name>, ~.<value> });
    ((%attr<rel> //= 'perl6') .= lc) ~~ s:g/\s+//;  # ::
    (%attr<class> ~= " syntax") ~~ s/^\s//;
    my $langname = pretty-lang-name %attr<rel>;
    
    if .<tag> || .<code> {
        info "Skipping $langname code at line $line, because it already "
           ~ "contains HTML tags.";
        next;
    }
    
    info "Highlighting $langname code at line $line...";
    substr-rw($source, .from, .chars)
      = write-html-tag('code', %attr)
      ~ syntax-highlight(HTML::Entity::decode(.<text>.join), lang => %attr<rel>)
      ~ .<comment>.join
      ~ '</code>';
}

print $source;
exit;

#------ Grammars ------#

grammar HtmlWithCode {
    rule TOP { [ .+? [<.comment> || <code> || <.tag>]*]* }
    rule code { :i
        '<code' [ <attr> || <-[>]>]* '>'
        [<code> || <tag> || <comment> || $<text>=[.+?]]*?
        [$ || '</code>']
    }
    rule tag { '</'<name> | '<'<name> [ <-[>]>*? <attr> ]* '>'};
    rule attr { <name> '=' [ | $<value>=[<-["'>\s]>+]       # "
                             | \" $<value>=[<-["]>+] \"     # "
                             | \' $<value>=[<-[']>+] \' ] } # '
    token name { <.alpha>\w* }
    token comment { '<!--' .*? '-->' };
}

#------ Subroutines ------#

#| Construct an opening tag for an HTML element, e.g. '<code class="syntax">'
sub write-html-tag ($name, %attributes) {
    '<' ~ $name ~ %attributes.map(-> $a {
        ' ' ~ $a.key ~ '='
            ~ ($a.value.match(/\"/) ?? qq['{$a.value}'] !! qq["{$a.value}"])
    }).join ~ '>';
}

#| Add syntax highlighting tags to a piece of code of the specified language
sub syntax-highlight ($sourcecode, :$lang!) {
    state ($in, $out) = ("$*TMPDIR/p6adv_$_-$*USER" for <in out>);
    
    spurt $in, $sourcecode;
    
    my $status = run «pygmentize -f html -O nowrap -l "$lang" -o "$out" "$in"»;
    +$status >= 0 or error "Could not run `pygmentize`. "
                         ~ "Make sure that you have Pygments installed.";
    $status or error "`pygmentize` failed.";
    
    slurp $out;
}

#| Prettify a Pygments lexer name for human eyes, e.g. 'perl6' --> 'Perl 6'
sub pretty-lang-name ($lang) {
    $lang.subst(/<before \d+>/, " ").tc;
}

sub info ($msg) { note " - {c 33}{$msg}{c}" }
sub error ($msg) { note "{c 1,31}Error: {c 0,31}{$msg}{c}"; exit 1 }
sub c is pure { (state $c = $*DISTRO.is-win) ?? ''
                    !! "\x1b[" ~ join(';', @_ || '0') ~ "m" }
