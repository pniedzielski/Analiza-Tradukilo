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

=head1 NAME

AnalizaTradukilo::Frazanalizo - Subrutinaro por analizi frazojn.

=head1 VERSION

La versio 1.0ª

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

Ĉi tiu subrutinaro enhavas subrutinojn, kiuj helpas onin analizi
gramatikon de Esperanta frazo.

=head2 Subroutines

=over 4

=item B<analizi_frazon($vortoj_en_frazo)>

Analizas frazon per la vortoj en la frazo.

Ĉi tiu subrutino funkcias per „X' teorio“ („Ikso-stango teorio“,
laŭangle „X-bar theory“).

=cut

sub analizi_frazon {
    my $vortoj_en_frazo = shift
        || die "Neniuj vortoj donitaj al „analizi_frazon“";

    my $arbo = [];
    for (my $i = 0; $i < scalar(@$vortoj_en_frazo); ++$i) {
        my $vorto = $vortoj_en_frazo->[$i];
        if (ĉu_artikolo($vorto)) {
            push $arbo, nova_np($vortoj_en_frazo, $vorto, \$i);
        } elsif ($vorto->{'finaĵo'} =~ /^[oa]j?n?$/) {
            --$i;
            push $arbo, nova_np($vortoj_en_frazo, '', \$i);
        } elsif (ĉu_pronomo($vorto->{'originala'})) {
            push $arbo, nova_pronoma_np($vorto);
        } elsif ($vorto->{'finaĵo'} =~ /^[aiou]s|u$/) {
            my $nova_v_duobla_stango =
                ['VP', ["V'", ['V', $vorto]]];
            push $arbo, $nova_v_duobla_stango;
        }
    }
    
    return $arbo;
}

sub nova_pronoma_np {
    my $pronomo = shift
        || die;
    
    return ['NP', ["N'", ['N', $pronomo]]];
}

sub nova_np {
    my $vortoj_en_frazo = shift
        || die;
    my $spec = shift;
    my $i = shift;

    my $np = ['NP', ["N'"]];
    $np = ['NP', ['SPEC', $spec], ["N'"]] if defined $spec && $spec ne '';

    my $ĉu_akuzativa = -1; # nesciita
    my $akuzativa_regex = 'n?';
    while (1) {
        last unless defined $vortoj_en_frazo->[++$$i];
        my $vorto = $vortoj_en_frazo->[$$i];
        if ($ĉu_akuzativa == 1) {
            $akuzativa_regex = 'n';
        } elsif ($ĉu_akuzativa == 0) {
            $akuzativa_regex = '';
        }
        if ($vorto->{'finaĵo'} =~ /^oj?$akuzativa_regex$/) {
            my $n_stango = redoni_plej_profundan_x_stangon($np);
            push $n_stango, ['N', $vorto];
            
            $ĉu_akuzativa = 0;
            $ĉu_akuzativa = 1 if ($vorto->{'finaĵo'} =~ /n$/);
        } elsif ($vorto->{'finaĵo'} =~ /^a$akuzativa_regex$/) {
            aldoni_komplementon($np, ['COMP', ['AP', ["A'", ['A', $vorto]]]]);
            
            $ĉu_akuzativa = 0;
            $ĉu_akuzativa = 1 if ($vorto->{'finaĵo'} =~ /n$/);
        } elsif ($vorto->{'originala'} eq 'de') {
            my $adjunkto = ["N'", $np->[-1],
                            ['ADJ', nova_pp($vortoj_en_frazo, $vorto, $i)]];
            $np->[-1] = $adjunkto;
            last;
        } else {
            --$$i;
            last;
        }
    }
    return $np;
}

sub nova_pp {
    my $vortoj_en_frazo = shift
        || die "Neniuj vortoj donitaj al „nova_pp“";
    my $prepozicio = shift
        || die "Neniu prepozicio donita al „nova_pp“";
    my $i = shift
        || die "Neniu loko donita al „nova_pp“";

    my $pp = ['PP', ["P'", ['P', $prepozicio]]];

    my $vorto = @$vortoj_en_frazo[++$$i];
    my $artikolo;
    $artikolo = $vorto if ĉu_artikolo($vorto);
    --$$i if !defined $artikolo;
    push $pp->[1], ['COMP', nova_np($vortoj_en_frazo, $artikolo, $i)];

    return $pp;
}

sub ĉu_artikolo{
    my $radikaro = trovi_radikaron_uzi($_[0]);
    return 1 if (scalar(@$radikaro) == 1 && $radikaro->[0] eq 'la');
    return 0;
}

sub aldoni_komplementon {
    my $x_duobla_stango = shift
        || die "Neniu XP donita al „aldoni_komplementon“";
    my $komplementon = shift
        || die "Neniu komplemento donita al „aldoni_komplementon“";

    # Kio estas la X?
    my $tipo = substr($x_duobla_stango->[0], 0, 1);

    my $plej_profunda_x_stango =
        redoni_plej_profundan_x_stangon($x_duobla_stango);

    # Se elemento -1a estas X, ...; alie, ...
    if (scalar(@$plej_profunda_x_stango) != 1) {
        if (ref $plej_profunda_x_stango->[-1] eq 'ARRAY' &&
            $plej_profunda_x_stango->[-1][0] =~ /^$tipo$/) {
            splice @$plej_profunda_x_stango, -1, 0, $komplementon;
        } else {
            push @$plej_profunda_x_stango, $komplementon;
        }
    } else {
        push @$plej_profunda_x_stango, $komplementon;
    }
}

sub redoni_plej_profundan_x_stangon {
    my $x_duobla_stango = shift
        || die "Neniu XP donita al „redoni_plej_profundan_x_stangon“";

    # Kio estas la X?
    my $tipo = substr($x_duobla_stango->[0], 0, 1);
    
    my $pleja;
    for $pleja (@$x_duobla_stango) {
        next unless ref $pleja eq 'ARRAY';
        if ($pleja->[0] =~ /^$tipo'$/) {
            my $nova_pleja = redoni_plej_profundan_x_stangon($pleja);
            $pleja = $nova_pleja if ref $nova_pleja eq 'ARRAY';
            return $pleja;
        }
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
