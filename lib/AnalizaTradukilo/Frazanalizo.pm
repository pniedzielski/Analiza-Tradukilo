#!/usr/bin/env perl

# Analiza Tradukilo: Tradukas de Esperanto al la angla.
# Copyright © 2012 Patrick M. Niedzielski.
#
# Ĉi tiu subrutinaro estas libera softvaro: vin oni permesas redonadi
# ĝin kaj/aŭ ŝanĝi ĝin laŭ la kondiĉoj de la GNU Affero General Public
# License, kiel eldonis la Free Software Foundation, aŭ la versio 3ª
# de la permisilo, aŭ (se vi volas) iu posta versio.
#
# Ĉi tiun subrutinaron donadis oni pro tiu espero, ke ĝi estu utila,
# sed SEN IA GARANTIO; sen eĉ la implica garantio de VENDEBLECO aŭ
# TAŬGECO POR CERTA CELO.  Vidu la GNU Affero General Public License
# trovi plie da detaloj.
#
# Vi jam ricevu kopion de la GNU Affero General Public License kun ĉi
# tiu subrutinaro.  Se ne, vidu <http://www.gnu.org/licenses/>.

package AnalizaTradukilo::Frazanalizo;

use Modern::Perl;
use encoding "utf-8";
use utf8;
use feature 'unicode_strings';
use locale ':not_characters';
binmode STDOUT, ":utf8";
binmode STDERR, ":utf8";

use base 'Exporter';
our @EXPORT = qw( analizi_frazon );

use Data::Dumper;

=head1 NAME

AnalizaTradukilo::Frazanalizo - Subrutinaro por analizi frazojn.

=head1 VERSION

La versio 2.0ª

=cut

our $VERSION = '1.0';

=head1 SYNOPSIS

Uzu ĉi tiun subrutinaron tiele:

    use AnalizaTradukilo::Frazanalizo;
    # Analizi vortojn:
    use AnalizaTradukilo::Radikanalizo;
    my @vortanalizoj = ();
    foreach my $vorto (qw( la katon mi amas )) {
        push @vortanalizoj, analizi_radikojn($vorto);
    }
    my $analizo = analizi_frazon(\@vortanalizoj);

=head1 DESCRIPTION

Ĉi tiu subrutinaro enhavas subrutinojn, kiu helpas onin analizi
gramatikon de Esperanta frazo.

=head2 Subroutines

=over 4

=item B<analizi_frazon($vortoj_en_frazo)>

Analizas frazon.

Ĉi tiu subrutino funkcias per „X' teorio“ („Ikso-stango teorio“,
laŭangle „X-bar theory“).

=cut

sub analizi_frazon {
    my $vortoj_en_frazo = shift
        || die "Neniuj vortoj donitaj al „analizi_frazon“";

    my $duoblaj_stangoj = [];
    for (my $i = 0; $i < scalar(@$vortoj_en_frazo); ++$i) {
        my $vorto = $vortoj_en_frazo->[$i];
        my $radikaro = trovi_radikaron_uzi($vorto);

        if (scalar(@$radikaro) == 1 && $radikaro->[0] eq 'la') {
            my $nova_n_duobla_stango = ['NP', ['determ', $vorto]];

            # Testu la sekvan vorton: ĉu estas substantivo?
            $vorto = $vortoj_en_frazo->[++$i];
            $radikaro = trovi_radikaron_uzi($vorto);
            if ($vorto->{'finaĵo'} =~ /^on?$/) {
                push $nova_n_duobla_stango, ["N'", $vorto];
            }
            push $duoblaj_stangoj, $nova_n_duobla_stango;
        } elsif ($vorto->{'finaĵo'} =~ /^on?$/) {
            my $nova_n_duobla_stango =
                ['NP', ["N'", $vorto]];
            push $duoblaj_stangoj, $nova_n_duobla_stango;
        } elsif ($vorto->{'finaĵo'} =~ /^[aiou]s|u$/) {
            my $nova_v_duobla_stango =
                ['VP', ["V'", $vorto]];
            push $duoblaj_stangoj, $nova_v_duobla_stango;
        } elsif ($vorto->{'finaĵo'} =~ /^n?$/ &&
                 ĉu_pronomo($vorto->{'originala'})) {
            my $nova_n_duobla_stango =
                ['NP', ["N'", $vorto]];
            push $duoblaj_stangoj, $nova_n_duobla_stango;
        }
    }

    # Se la verbo povas havi subjekton kaj objekton...
    # TODO: ĝin provu.
    my ($verbo, $subjekto, $objekto);
    my ($verbo_loko, $subjekto_loko, $objekto_loko) = (0, 0, 0);
    for (my $j = 0; $j < scalar(@$duoblaj_stangoj); ++$j) {
        for ($duoblaj_stangoj->[$j]) {
            if (ĉu_havas_stangon($_)) {
                my $stango = redoni_stangon($_);
                if ($stango->[0] eq "V'") {
                    $verbo = $_;
                    $verbo_loko = $j;
                } elsif ($stango->[0] eq "N'") {
                    if ($stango->[1]->{'finaĵo'} eq 'o' ||
                        ($stango->[1]->{'finaĵo'} eq '' &&
                         ĉu_pronomo($stango->[1]->{'originala'}))) {
                        $subjekto = $_;
                        $subjekto_loko = $j;
                    } else {
                        $objekto = $_;
                        $objekto_loko = $j;
                    }
                }
            }
        }
    }
    if (defined $verbo and defined $subjekto) {
        splice @$verbo, 1, 0, $subjekto;
        splice @$duoblaj_stangoj, $subjekto_loko, 1;
        --$objekto_loko if $objekto_loko > $subjekto_loko;
    }
    if (defined $verbo and defined $objekto) {
        push $verbo, $objekto;
        splice @$duoblaj_stangoj, $objekto_loko, 1;
        --$subjekto_loko if $subjekto_loko > $objekto_loko;
    }
    
    say Dumper $duoblaj_stangoj;
}

sub ĉu_havas_subjekton {
    for ($_[0]) {
        return 1 if $_->[1]->[0] eq "N'";
        return 0;
    }
}

sub ĉu_havas_objekton {
    for ($_[0]) {
        my $lasta = scalar(@$_)-1;
        return 1 if $_->[$lasta]->[0] eq "N'";
        return 0;
    }
}

sub ĉu_pronomo {
    for ($_[0]) {
        return m/^(?:m|n|c|v|l|ŝ|ĝ|il|on|s)in?/;
    }
}

sub trovi_radikaron_uzi {
    my $radikaro;
    my $radikaro_rango = -10000;
    foreach (@{$_[0]->{'eblaj_radikaroj'}}) {
        if ($_->{'rango'} > $radikaro_rango) {
            $radikaro_rango = $_->{'rango'};
            $radikaro = $_->{'ebla_radikaro'};
        }
    }
    return $radikaro;
}

sub ĉu_havas_stangon {
    my $tipo = substr($_[0]->[0], 0, 1);
    for (1..(scalar(@{$_[0]})-1)) {
        return 1 if ($_[0]->[$_]->[0] eq $tipo."'");
    }
    return 0;
}

sub redoni_stangon {
    my $tipo = substr($_[0]->[0], 0, 1);
    for (1..(scalar(@{$_[0]})-1)) {
        return $_[0]->[$_] if ($_[0]->[$_]->[0] eq $tipo."'");
    }
    return undef;
}



=back

=head1 BUGS

Jam sciitaj problemoj:


=head1 AUTHORS

Tiun ĉi subrutinaron skribigis Patrick M. Niedzielski
C<< <PatrickNiedzielski@gmail.com> >>.

=head1 COPYRIGHT AND LICENSE

Copyright © 2012 Patrick M. Niedzielski.

Ĉi tiu subrutinaro estas libera softvaro: vin oni permesas redonadi
ĝin kaj/aŭ ŝanĝi ĝin laŭ la kondiĉoj de la GNU Affero General Public
License, kiel eldonis la Free Software Foundation, aŭ la versio 3ª
de la permisilo, aŭ (se vi volas) iu posta versio.

Ĉi tiun subrutinaron donadis oni pro tiu espero, ke ĝi estu utila, sed
SEN IA GARANTIO; sen eĉ la implica garantio de VENDEBLECO aŭ TAŬGECO
POR CERTA CELO.  Vidu la GNU Affero General Public License trovi
plie da detaloj.

Vi jam ricevu kopion de la GNU Affero General Public License kun ĉi
tiu subrutinaro.  Se ne, vidu L<http://www.gnu.org/licenses/>.

=cut

1;
__END__
