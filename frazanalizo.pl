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
use AnalizaTradukilo::Frazanalizo;

use Data::Dumper::Perltidy;
$Data::Dumper::Perltidy::ARGV = '-pbp -nst';

my @vortanalizoj = ();
foreach my $vorto (qw( la proprita amita kato granda estis feliĉa )) {
    push @vortanalizoj, analizi_radikojn($vorto);
}
say Dumper analizi_frazon(\@vortanalizoj);

__END__
