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

use base 'Exporter';
our @EXPORT = qw( ŝargi_radikaron ĉu_radiko );

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

=head1 PRISKRIBO

=head2 Subrutinoj

=over 4

=item B<ŝargi_radikaron()>

=item B<ŝargi_radikaron($file)>

Ŝargas iun radikar-dosieron en memorion.  Tiu for ŝargas la dosieron
ĉe „data/radikaro“; tiu ĉi ŝargas la dosieron donitan.

=cut

# Malpublika aro de niaj radikoj.  La subrutino „ŝargi_radikaron“ ĉi
# tion plenigas.
our %radikaro;

sub ŝargi_radikaron {
    my $dosiero = shift || "data/radikaro";

    # $vortdosiero estos fermita post la bloko.
    my $vortdosiero;
    open ($vortdosiero, "<:encoding(utf8)", $dosiero)
        || die "Ŝargado de radikaro $dosiero: $!";
    my @vortaj_datoj = <$vortdosiero>;
    for (@vortaj_datoj) {
        /^(.+)\s+(.+)$/;
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

=back

=head1 PROBLEMOJ

Jam sciitaj problemoj:

Ĉi tiu modulo ne povas analizi vortojn, kiu enhavas nesciitajn
radikojn, inkluzive propajn nomojn.

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
