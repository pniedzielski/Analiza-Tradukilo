#!/usr/bin/env perl

# Analiza Tradukilo: Tradukas de Esperanto al la angla.
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

package AnalizaTradukilo::Radikanalizo;

use Modern::Perl;
use encoding "utf-8";
use utf8;
use feature 'unicode_strings';
use locale ':not_characters';
binmode STDOUT, ":utf8";
binmode STDERR, ":utf8";

use Data::Dumper;

use base 'Exporter';
our @EXPORT = qw( ŝargi_radikaron
                  ĉu_radiko
                  ĉu_senfinaĵa_vorto
                  forviŝi_finaĵon
                  analizi_radikojn );

=head1 NOMO

AnalizaTradukilo::Radikanalizo - Subrutinaro por analizi radikojn en
vorto

=head1 VERSIO

La versio 2.0ª

=cut

our $VERSION = '2.0';

=head1 RESUMO

Uzu ĉi tiun subrutinaron tiele:

    use AnalizaTradukilo::Radikanalizo;
    ŝargi_radikaron;
    my $analizo = analizi_radikojn("amuzo");

=head1 PRISKRIBO

Ĉi tiu subrutinaro enhavas subrutinojn, kiu helpas onin analizi la
radikojn de vortoj Esperantaj.

=head2 Subrutinoj

=over 4

=item B<ŝargi_radikaron()>

=item B<ŝargi_radikaron($file)>

Ŝargas iun radikar-dosieron en memorion.  Tiu for ŝargas la dosieron
ĉe „data/radikaro“; tiu ĉi ŝargas la dosieron donitan.

Ĉiu vico en radikar-dosiero devas havi unu el la sekvantajn formojn:

    # komento....

    radiko tipo vorto

kie C<vorto> ne estas lokokupa vorto.

=cut

# Malpublika aro de niaj radikoj.  La subrutino „ŝargi_radikaron“ ĉi
# tion plenigos.
our %radikaro;
# Malpublika aro de niaj nefinaĵaj vortoj.  La subrutino
# „ŝargi_radikaron“ ĉi tion plenigos.
our %vortoj;

sub ŝargi_radikaron {
    my $dosiero = shift || "data/radikaro";

    # $vortdosiero estos fermita post la bloko.
    my $vortdosiero;
    open ($vortdosiero, "<:encoding(utf8)", $dosiero)
        || die "Ŝargado de radikaro $dosiero: $!";
    my @vortaj_datoj = <$vortdosiero>;
    for (@vortaj_datoj) {
        next if /^\s*\#/;       # Komento
        /^(.+)\s+(.+)\s+((?:vorto)?)$/;
        # Se senfinaĵa vorto:
        $vortoj{$1} = undef if (defined($3) && $3 eq 'vorto');
        $radikaro{$1} = $2;
    }
}

=item B<ĉu_radiko($kordeto)>

Redonas, ĉu iu donita kordeto estas sciita radiko.

=cut

sub ĉu_radiko {
    my $radiko = shift
        || die "Neniu radiko donita al „ĉu_radiko“";
    return exists $radikaro{$radiko};
}

=item B<ĉu_senfinaĵa_vorto($kordeto)>

Redonas, ĉu iu donita kordeto estas sciita vorto, kiu ne havas
finaĵon.

=cut

sub ĉu_senfinaĵa_vorto {
    my $vorto = shift
        || die "Neniu vorto donita al „ĉu_senfinaĵa_vorto“";
    return exists $vortoj{$vorto};
}

=item B<forviŝi_finaĵon($vorto)>

Redonas strukturon, kiu enhavas la vorton sen finaĵo kaj la finaĵon.
Se estas tia vorto, kiaj „mi“ kaj „ne“, kiu ne finiĝas per finaĵo, sed
kies lastaj literoj estas iu finaĵo, ĉi tiu subrutino ankoraŭ agos
tiel, kiel la vorto ja havus finaĵon.

La strukturo, kiun ĉi tiu subrutino redonas, havas la sekvantan
formon:

    $elvorto = [
        'o',
        'amuz'
    ];

=cut

sub forviŝi_finaĵon {
    my $vorto = shift
        || die "Neniu vorto donita al „analizi_radikojn“";

    my @finaĵoj = ('o', 'on', 'oj', 'ojn',           # substantivoj
                   'a', 'an', 'aj', 'ajn',           # adjektivoj
                   'as', 'os', 'is', 'us', 'u', 'i', # verboj
                   'e', 'en');                       # adverboj

    for ($vorto) {
        # Unue, ni provos, ĉu la vorto finiĝas per „'“.  Se jes,
        # redonu „o“, ne „'“.
        return ['o', s/'$//r] if /'$/;

        # Alie, serĉu finaĵon.
        foreach my $finaĵo (@finaĵoj) {
            return [$finaĵo, s/$finaĵo$//r] if /$finaĵo$/;
        }

        # Ni ne trovis finaĵon ĉe ĉi tiu vorto.
        return ['', $_];
    }
}

=item B<analizi_radikojn($vorto)>

Redonas strukturon, kiu enhavas la radikojn de C<$vorto>.  Se la vorto
enhavas radikojn nesciitajn, la tutan nefinaĵan parton supozas oni
esti radikon.

La strukturo, kiun ĉi tiu subrutino redonas, havas la sekvantan
formon:

    $analizo = {
        originala       => 'amuzo',
        finaĵon         => 'o',
        eblaj_radikaroj => [
            [
                am,
                uz
            ],
            [
                amuz
            ]
        ]
    };

=cut

sub analizi_radikojn {
    my $vorto = shift
        || die "Neniu vorto donita al „analizi_radikojn“";
    die "Nevalida vorto donita al „analizi_radikojn“" unless /[a-z]+/;

    my $analizo = { originala => $vorto };

    # Se la vorto ne havas finaĵon (tiaj vortoj, kiaj „unu“ aŭ „ĉar“),
    # nur ĝin uzu.  Alie, ni devas forviŝi la finaĵon kaj vere analizi
    # la radikojn de la vorto.
    if (ĉu_senfinaĵa_vorto($vorto)) {
        $analizo->{'finaĵo'} = '';
        $analizo->{'eblaj_radikaroj'} = [[$vorto]];
    } else {
        my $finaĵo_strukturo = forviŝi_finaĵon($vorto);
        $analizo->{'finaĵo'} = $finaĵo_strukturo->[0];

        # Se estas neniu analizo, nur uzu la vorton (sen finaĵo), kiel
        # la ebla radikaro.  Se ekzistas analizo, ĝin uzu.
        my $eblaj_radikaroj =
            analizi_radikojn_helpilo($finaĵo_strukturo->[1]);
        $analizo->{'eblaj_radikaroj'} = [];
        $analizo->{'eblaj_radikaroj'} = $eblaj_radikaroj
            if scalar(@$eblaj_radikaroj) != 0;

        # Ke la tuta vorto estas radiko, ĉiam estas verŝajneco.  Ni ne
        # volas aldoni ĝin al la eblaj radikaroj, se ĝi jam estas en
        # tiu listo.
        my $ĉu_en_listo = 0;
        foreach my $ebla_radikaro (@$eblaj_radikaroj) {
            # Se la unua elemento en la listo estas la sama, la tuta
            # listoj estas samaj.
            $ĉu_en_listo = 1
                if $ebla_radikaro->[0] eq $finaĵo_strukturo->[1];
        }
        push $analizo->{'eblaj_radikaroj'}, [$finaĵo_strukturo->[1]]
            if !$ĉu_en_listo;
    }

    return $analizo;
}

# Serĉas radikojn en multradika vorto.
sub analizi_radikojn_helpilo {
    my $_ = shift;              # Ne devas „|| die“ ĉi tie.
    return [[]]   if !defined($_);
    return [[]]   if /^$/;      # Se neniom da leteroj.
    return [[$_]] if /^.$/;     # Se nur unu letero.
    my ($longeco, $pliaj, $lastaj) = (0, [], []);
    for $longeco (1..(length $_)) {
        /^(.{$longeco})(.*)$/;
        next unless ĉu_radiko($1);
        my $trovita = $1;
        $pliaj = analizi_radikojn_helpilo($2);
        foreach my $radikoj (@$pliaj) {
            unshift($radikoj, $trovita);
        }
        push ($lastaj, @$pliaj);
    }
    return $lastaj;
}

=back

=head1 PROBLEMOJ

Jam sciitaj problemoj:

Ĉi tiu modulo ne povas analizi vortojn, kiu enhavas nesciitajn
radikojn, inkluzive propajn nomojn.

Ĉiu ebla radikaro, kiun ni trovas, havas la saman verŝajnecon, eĉ se
unu estas ege pli bona ol la aliaj.

=head1 AŬTORO

Tiun ĉi modulon skribigis Patrick M. Niedzielski
C<PatrickNiedzielski@gmail.com>.

=head1 KOPIRAJTO KAJ KONDIĈOJ

Copyright © 2012 Patrick M. Niedzielski.

Ĉi tiu programo estas libera softvaro: vin oni permesas redonadi ĝin
kaj/aŭ ŝanĝi ĝin laŭ la kondiĉoj de la GNU Affero General Public
License, kiel eldonis la Free Software Foundation, aŭ la versio 3ª
de la permisilo, aŭ (se vi volas) iu posta versio.

Ĉi tiun programon donadis oni pro tiu espero, ke ĝi estu utila, sed
SEN IA GARANTIO; sen eĉ la implica garantio de VENDEBLECO aŭ TAŬGECO
POR CERTA CELO.  Vidu la GNU Affero General Public License trovi
plie da detaloj.

Vi jam ricevu kopion de la GNU Affero General Public License kun ĉi
tiu programo.  Se ne, vidu L<http://www.gnu.org/licenses/>.

=cut

1;
__END__
