#!/usr/bin/env perl

# krei-radikaro.pl - Kreas radikar-dosieron por la Analiza Tradukilo.
# Copyright © 2012 Patrick M. Niedzielski.
#
# Ĉi tiu programo estas libera softvaro: vin oni permesas redonadi ĝin
# kaj/aŭ ŝanĝi ĝin laŭ la kondiĉoj de la GNU Affero General Public
# License, kiel eldonis la Free Software Foundation, aŭ la versio 3ª
# de la permisilo, aŭ (se vi volas) iu posta versio.
#
# Ĉi tiun programon donadis oni pro tiu espero, ke ĝi estu utila, sed
# SEN IA GARANTIO; sen eĉ la implica garantio de VENDEBLECO aŭ TAŬGECO
# POR CERTA CELO.  Vidu la GNU Affero General Public License trovi
# plie da detaloj.
#
# Vi jam ricevu kopion de la GNU Affero General Public License kun ĉi
# tiu programo.  Se ne, vidu <http://www.gnu.org/licenses/>.

use Modern::Perl;
use encoding "utf-8";
use utf8;
use feature 'unicode_strings';
use locale ':not_characters';
binmode STDOUT, ":utf8";
binmode STDERR, ":utf8";

use LWP::UserAgent;
use HTML::Entities;

# Se estas argumento, ja petu.
my $petu_kiam_nescia = 1;

my %prepozicioj;
my %konjunkcioj;
my %interjektoj;
my %vortetoj;
my %nombroj;

my $peristo = LWP::UserAgent->new();

my $respondo = $peristo->get('https://en.wiktionary.org/w/index.php?title=Category:Esperanto_prepositions');
if ($respondo->is_success) {
    my @datoj = split('\n', decode_entities($respondo->decoded_content));
    for (@datoj) {
        next unless /<li><a href="\/wiki\/.*" title=".*">(.*)<\/a><\/li>/;
        last if $1 =~ /by language$/;
        next if $1 =~ / /;
        next if $1 =~ /x/;
        $prepozicioj{$1} = undef;
    }
} else {
    print "Error: " . $respondo->status_line;
}

$respondo = $peristo->get('https://en.wiktionary.org/wiki/Category:Esperanto_conjunctions');
if ($respondo->is_success) {
    my @datoj = split('\n', decode_entities($respondo->decoded_content));
    for (@datoj) {
        next unless /<li><a href="\/wiki\/.*" title=".*">(.*)<\/a><\/li>/;
        last if $1 =~ /by language$/;
        next if $1 =~ / /;
        next if $1 =~ /x/;
        my $vorto = $1;
        $vorto =~ s/-//;
        $konjunkcioj{$vorto} = undef;
    }
} else {
    print "Error: " . $respondo->status_line;
}

$respondo = $peristo->get('https://en.wiktionary.org/wiki/Category:Esperanto_interjections');
if ($respondo->is_success) {
    my @datoj = split('\n', decode_entities($respondo->decoded_content));
    for (@datoj) {
        next unless /<li><a href="\/wiki\/.*" title=".*">(.*)<\/a><\/li>/;
        last if $1 =~ /by language$/;
        next if $1 =~ / /;
        my $vorto = $1;
        $vorto =~ s/-//;
        $interjektoj{$vorto} = undef;
    }
} else {
    print "Error: " . $respondo->status_line;
}

$respondo = $peristo->get('https://en.wiktionary.org/wiki/Category:Esperanto_particles');
if ($respondo->is_success) {
    my @datoj = split('\n', decode_entities($respondo->decoded_content));
    for (@datoj) {
        next unless /<li><a href="\/wiki\/.*" title=".*">(.*)<\/a><\/li>/;
        last if $1 =~ /by language$/;
        $vortetoj{$1} = undef;
    }
} else {
    print "Error: " . $respondo->status_line;
}

$respondo = $peristo->get('https://en.wiktionary.org/wiki/Category:eo:Cardinal_numbers');
if ($respondo->is_success) {
    my @datoj = split('\n', decode_entities($respondo->decoded_content));
    for (@datoj) {
        next unless /<li><a href="\/wiki\/.*" title=".*">(.*)<\/a><\/li>/;
        last if $1 =~ /by language$/;
        next if $1 =~ / /;
        $nombroj{$1} = undef;
    }
} else {
    print "Error: " . $respondo->status_line;
}

my @vortoj;

$respondo = $peristo->get('http://pilger.home.xs4all.nl/breo-au8.htm');
if ($respondo->is_success) {
    my @datoj = split('\n', decode_entities($respondo->decoded_content));
    for (@datoj) {
        next unless /^<B>(.+?) :.*?<\/B>/mg;
        next if $1 =~ /\-/g;
        next if $1 =~ /\./g;
        my $dato = $1;
        $dato =~ s/\!//g;
        next if exists $prepozicioj{$dato} or
            exists $konjunkcioj{$dato} or
            exists $interjektoj{$dato} or
            exists $vortetoj{$dato} or
            exists $nombroj{$dato};
        push @vortoj, $dato;
    }
} else {
    print "Error: " . $respondo->status_line;
}

foreach (@vortoj) {
    # Unue certiĝi pri tio, ke la vorto estu korelativo.
    if (/^(ĉi|i|neni|ti|ki)(al|am|el|es|om|u|o|a|e)$/) {
        say $_ . "\tkorelativa";
        next;
    }

    # Poste certiĝi pri tio, ke la vorto estu pronomo.
    if (/^(mi|ni|ci|vi|li|ŝi|ĝi|ili|si|oni)$/) {
        say $1 . "\tpronoma";
        next;
    }

    $_ =~ s/(o|oj|aj|i|a|e)$//mg;
    next if /^.$/;
    next if /\-/g;
    print $_;
    my $finaĵo = $1;
    if (!defined $finaĵo) {
        if ($petu_kiam_nescia) {
            my $tipo = <>;
            print "\t$tipo"; # neniu \n ĉi tie; la $tipo jam havas unu
        } else {
            print "\tnescia\n";
        }
    } elsif ($finaĵo =~ /o|oj/) {
        print "\tsubstantiva\n";
    } elsif ($finaĵo =~ /i/) {
        print "\tverba\n";
    } elsif ($finaĵo =~ /a|oj/) {
        print "\tadjektiva\n";
    } elsif ($finaĵo =~ /e/) {
        print "\tadverba\n";
    } else {
        if ($petu_kiam_nescia) {
            my $tipo = <>;
            print "\t$tipo"; # neniu \n ĉi tie; la $tipo jam havas unu
        } else {
            print "\tnescia\n";
        }
    }
}

for (%konjunkcioj) {
    say $_ . "\tkonjunkcia" if defined $_;
}
for (%prepozicioj) {
    say $_ . "\tprepozicia" if defined $_;
}
for (%interjektoj) {
    say $_ . "\tinterjekta" if defined $_;
}
for (%vortetoj) {
    say $_ . "\tvorteta"    if defined $_;
}
for (%nombroj) {
    say $_ . "\tnombra"     if defined $_;
}

__END__
