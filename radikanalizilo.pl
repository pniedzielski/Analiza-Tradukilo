#!/usr/bin/env perl

# radikanalizilo.pl - Skribas eblajn radikojn de vorto.
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

use lib "./lib";
use AnalizaTradukilo::Radikanalizo;

use Data::Dumper;

sub inviton {
    print ">> ";
}

sub pri_programo {
    say <<'FINO';
radikanalizilo.pl: Copyright © 2012 Patrick M. Niedzielski.
Ĉi tiun programon donadis oni SEN IA GARANTIO; tajpu „!g“ vidi detalojn.
Ĉi tiu programo estas libera softvaro: vin oni permesas redonadi ĝin laŭ
certaj kondiĉoj; tajpu „!k“ vidi detalojn.  Eliri, tajpu „!e“.  Ricevi
helpon, tajpu „!h“.  Aldoni radikon, tajpu „!ar“ kaj sekve la radikon
kaj ĝian tipon.  Aldoni vorton senfinaĵan, tajpu „!av“ kaj sekve la
vorton kaj ĝian tipon.
FINO
}

sub pri_garantio {
    print <<'FINO';
Ne estas ia garantio por la programo, kiom lasigas la aplikeblaj leĝoj.
Krom kiam alie skribite, la propruloj de la kopirajto kaj/aŭ aliaj aroj
donadas la programon „kiel estante“ sen ia garantio, aŭ dirata aŭ nedirita
inkluzive sed ne limitiĝe per, la implica garantio de VENDEBLECO aŭ
TAŬGECO POR CERTA CELO.  La tuto risko pri la boneco de la programo estas
kun vi.  Se la program havu problemon, vi alprenas la tuton koston de ĉiuj
necesaj riparadoj kaj pravigadoj.

Vidu la GNU Affero General Public License por pli detaloj.
FINO
}

sub pri_kondiĉoj {
    print <<'FINO';
Ĉi tiu programo estas libera softvaro: vin oni permesas redonadi ĝin
kaj/aŭ ŝanĝi ĝin laŭ la kondiĉoj de la GNU Affero General Public
License, kiel eldonis la Free Software Foundation, aŭ la versio 3ª
de la permisilo, aŭ (se vi volas) iu posta versio.

Ĉi tiun programon donadis oni pro tiu espero, ke ĝi estu utila, sed
SEN IA GARANTIO; sen eĉ la implica garantio de VENDEBLECO aŭ TAŬGECO
POR CERTA CELO.  Vidu la GNU Affero General Public License trovi
plie da detaloj.

Vi jam ricevu kopion de la GNU Affero General Public License kun ĉi
tiu programo.  Se ne, vidu <http://www.gnu.org/licenses/>.
FINO
}

sub pri_helpo {
    say <<'FINO';
Tajpu Esperantan vorton vidi eblajn radikojn.
FINO
    pri_programo;
}

my @nesciitaj_radikoj = ();
sub skribi_radikon {
    my $kordeto = $_[0];
    unless (ĉu_radiko($_[0])) {
        $kordeto .= '*';
        push @nesciitaj_radikoj, $_[0];
    }
    return $kordeto;
}

# Ŝargu la defaŭltan radikar-dosieron.
ŝargi_radikaron;

pri_programo;
inviton;
while (<>) {
    pri_garantio if /^!g$/;
    pri_kondiĉoj if /^!k$/;
    pri_helpo    if /^!h$/;
    last         if /^!e$/;

    aldoni_radikon($1, $2) and next if /^!ar\s+(.+)\s+(.+)/;
    aldoni_senfinaĵan_vorton($1, $2) and next if /^!av\s+(.+)\s+(.+)/;

    print <<'LINEFINO';
----------------------------------------------------------------------
LINEFINO

    chomp;
    $_ = lc;

    my $analizo = analizi_radikojn($_);
    print 'Mi ricevis ';
    if ($analizo->{'finaĵo'} eq '') {
        print 'senfinaĵan vorton; ';
    } else {
        print 'vorton finiĝantan per „', $analizo->{'finaĵo'}, '“; ';
    }

    say 'mi povas analizi ĝin tiel:';

    # Ordigi ilin:
    my @eblaj_radikaroj =
        sort {$a->{'rango'} cmp $b->{'rango'}}
            @{$analizo->{'eblaj_radikaroj'}};

    foreach my $ebla_radikaro (@eblaj_radikaroj) {
        print '  - Rango ', $ebla_radikaro->{'rango'}, ":\t";
        print skribi_radikon($ebla_radikaro->{'ebla_radikaro'}->[0]);
        for (1..(scalar(@{$ebla_radikaro->{'ebla_radikaro'}})-1)) {
            print ' + ';
            print skribi_radikon(
                $ebla_radikaro->{'ebla_radikaro'}->[$_]);
        }
        say '';
    }

    if (scalar(@nesciitaj_radikoj)) {
        say 'Mi ne scias la sekvantajn radikojn:';
        say "  - $_" foreach (@nesciitaj_radikoj);
    }

    print <<'LINEFINO';
----------------------------------------------------------------------
LINEFINO
} continue {
    @nesciitaj_radikoj = ();
    inviton;
}

say "Ĝis.";

__END__
