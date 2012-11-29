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

package AnalizaTradukilo::Radikanalizo;

use Modern::Perl;
use encoding "utf-8";
use utf8;
use feature 'unicode_strings';
use locale ':not_characters';
binmode STDOUT, ":utf8";
binmode STDERR, ":utf8";

use base 'Exporter';
our @EXPORT = qw( ŝargi_radikaron
                  aldoni_radikon
                  aldoni_senfinaĵan_vorton
                  ĉu_radiko
                  ĉu_senfinaĵa_vorto
                  ĉu_antaŭradiko
                  ĉu_postradiko
                  forviŝi_finaĵon
                  analizi_radikojn
                  rangi_eblan_radikaron
                  komputi_tipon_de_radikaron );

=head1 NAME

AnalizaTradukilo::Radikanalizo - Subrutinaro por analizi radikojn en
vorto

=head1 VERSION

La versio 2.0ª

=cut

our $VERSION = '2.0';

=head1 SYNOPSIS

Uzu ĉi tiun subrutinaron tiele:

    use AnalizaTradukilo::Radikanalizo;
    ŝargi_radikaron;
    my $analizo = analizi_radikojn("amuzo");

=head1 DESCRIPTION

Ĉi tiu subrutinaro enhavas subrutinojn, kiuj helpas onin analizi la
radikojn de vortoj Esperantaj.

=head2 Subroutines

=over 4

=item B<ŝargi_radikaron()>

=item B<ŝargi_radikaron($dosiero)>

Ŝargas iun radikar-dosieron en memorion.  Tiu for ŝargas la dosieron
ĉe F<data/radikaro>; tiu ĉi ŝargas la C<$dosiero>n donitan.

Ĉiu vico en radikar-dosiero devas havi unu el la sekvantajn formojn:

    # komento....
    radiko tipo
    radiko tipo vorto
    radiko tipo vorto antaŭ
    radiko tipo vorto post
    radiko tipo antaŭ
    radiko tipo post

kie C<vorto>, C<antaŭ>, kaj C<post> ne estas lokokupa vorto.

=cut

# Malpublika aro de niaj radikoj.  La subrutino „ŝargi_radikaron“ ĉi
# tion plenigos.
our %radikaro;
# Malpublika aro de niaj nefinaĵaj vortoj.  La subrutino
# „ŝargi_radikaron“ ĉi tion plenigos.
our %vortoj;
# Malpublika aro de niaj antaŭradikoj.  La subrutino „ŝargi_radikaron“
# ĉi tion plenigos.
our %antaŭradikoj;
# Malpublika aro de niaj postradikoj.  La subrutino „ŝargi_radikaron“
# ĉi tion plenigos.
our %postradikoj;

sub ŝargi_radikaron {
    my $dosiero = shift || "data/radikaro";

    # $vortdosiero estos fermita post la bloko.
    my $vortdosiero;
    open ($vortdosiero, "<:encoding(utf8)", $dosiero)
        || die "Ŝargado de radikaro $dosiero: $!";
    my @vortaj_datoj = <$vortdosiero>;
    for (@vortaj_datoj) {
        chomp;
        next if /^\s*\#/;       # Komento
        next unless /^(\w+)\s+(\w+),((?:\w+,)*)$/;
        my $radiko = $1;
        my $pri = $3;
        # Se senfinaĵa vorto:
        $vortoj{$radiko}       = undef if $pri =~ /vorto,/;
        $antaŭradikoj{$radiko} = undef if $pri =~ /antaŭ,/;
        $postradikoj{$radiko}  = undef if $pri =~ /post,/;
        $radikaro{$radiko}     = $2;
    }
}

=item B<aldoni_radikon($radiko, $tipo)>

Aldonas donitan C<$radiko>n de iu C<$tipo> al la radikaron de la
programo.  Ĉi tio lasas, ke la programo aldonu novajn vortojn
(proprajn nomojn, ktp), pri kiujn ĝi lernas dum tradukado.

=cut

sub aldoni_radikon {
    my ($radiko, $tipo) = shift
        || die "Radiko aŭ tipo ne donita al „aldoni_radikon“";

    $radikaro{$radiko} = $tipo;
}

=item B<aldoni_senfinaĵan_vorton($vorto, $tipo)>

Aldonas donitan C<$vorto>n de iu C<$tipo> al kaj la radikaron kaj la
vortaron de senfinaĵaj vortoj de la programo.  Ĉi tio lasas, ke la
programo aldonu novajn vortojn (proprajn nomojn, ktp), pri kiujn ĝi
lernas dum tradukado.

=cut

sub aldoni_senfinaĵan_vorton {
    my ($vorto, $tipo) = shift
        || die "Vorto aŭ tipo ne donita al „aldoni_senfinaĵan_vorton“";

    $vortoj{$vorto} = undef;
    aldoni_radikon($vorto, $tipo);
}

=item B<ĉu_radiko($kordeto)>

Redonas, ĉu iu donita C<$kordeto> estas sciita radiko.

=cut

sub ĉu_radiko {
    my $radiko = shift
        || die "Neniu radiko donita al „ĉu_radiko“";
    return exists $radikaro{$radiko};
}

=item B<ĉu_senfinaĵa_vorto($kordeto)>

Redonas, ĉu iu donita C<$kordeto> estas sciita vorto, kiu ne havas
finaĵon.

=cut

sub ĉu_senfinaĵa_vorto {
    my $vorto = shift
        || die "Neniu vorto donita al „ĉu_senfinaĵa_vorto“";
    return exists $vortoj{$vorto};
}

=item B<ĉu_antaŭradiko($kordeto)>

Redonas, ĉu iu donita C<$kordeto> estas antaŭradiko.

=cut

sub ĉu_antaŭradiko {
    my $kordeto = shift
        || die "Neniu radiko donita al „ĉu_antaŭradiko“";
    return exists $antaŭradikoj{$kordeto};
}

=item B<ĉu_postradiko($kordeto)>

Redonas, ĉu iu donita C<$kordeto> estas postradiko.

=cut

sub ĉu_postradiko {
    my $kordeto = shift
        || die "Neniu radiko donita al „ĉu_postradiko“";
    return exists $postradikoj{$kordeto};
}

=item B<forviŝi_finaĵon($vorto)>

Redonas strukturon, kiu enhavas la C<$vorto>n sen finaĵo kaj la
finaĵon.  Se estas tia C<$vorto>, kiaj „mi“ kaj „ne“, kiu ne finiĝas
per finaĵo, sed kies lastaj literoj estas iu finaĵo, ĉi tiu subrutino
ankoraŭ agos tiel, kiel la C<$vorto> ja havus finaĵon.

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
        # Ĉu estas „la“?
        return ['', 'la'] if /^l(?:'|a)$/;

        # Ĉu estas akuzativa pronomo?
        return ['n', s/n$//r] if /^(?:mi|ni|ci|vi|li|ŝi|ĝi|ili|si|oni)n$/;

        # Ĉu estas nominativa pronomo?
        return ['', $_] if /^(?:mi|ni|ci|vi|li|ŝi|ĝi|ili|si|oni)$/;

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

Redonas strukturon, kiu enhavas la radikojn de C<$vorto>.  Se la
C<$vorto> enhavas radikojn nesciitajn, la tutan nefinaĵan parton
supozas oni esti radikon.

La strukturo, kiun ĉi tiu subrutino redonas, havas la sekvantan
formon:

    $analizo = {
        originala       => 'amuzo',
        finaĵon         => 'o',
        eblaj_radikaroj => [
            {
                rango => -2,
                ebla_radikaro => [
                    am,
                    uz
                ]
            },
            {
                rango => -1,
                ebla_radikaro => [
                    amuz
                ]
            }
        ]
    };

=cut

sub analizi_radikojn {
    my $vorto = shift
        || die "Neniu vorto donita al „analizi_radikojn“";
    die "Nevalida vorto donita al „analizi_radikojn“"
        unless $vorto =~ /[a-z]+/;

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
    
    # Rangi eblajn radikarojn:
    my $radikaroj_kun_rangoj = [];
    foreach my $ebla_radikaro (@{$analizo->{'eblaj_radikaroj'}}) {
        push($radikaroj_kun_rangoj,
             rangi_eblan_radikaron($ebla_radikaro));
    }
    $analizo->{'eblaj_radikaroj'} = $radikaroj_kun_rangoj;

    return $analizo;
}

# Serĉas radikojn en multradika vorto.
sub analizi_radikojn_helpilo {
    my $_ = shift;              # Ne devas „|| die“ ĉi tie.
    return [[]]   if !defined($_);
    return [[]]   if /^$/;      # Se neniom da leteroj.
    my ($longeco, $pliaj, $lastaj) = (0, [], []);
    for $longeco (1..(length $_)) {
        /^(.{$longeco})(.*)$/;
        my $trovita = $1;
        next unless ĉu_radiko($trovita);
        $pliaj = analizi_radikojn_helpilo($2);
        foreach my $radikoj (@$pliaj) {
            unshift $radikoj, $trovita;
        }
        push $lastaj, @$pliaj;
    }
    for $longeco (1..((length $_)-1)) {
        next unless /^(.{$longeco})[oaei](.*)$/;
        my $trovita = $1;
        next unless ĉu_radiko($trovita);
        $pliaj = analizi_radikojn_helpilo($2);
        foreach my $radikoj (@$pliaj) {
            unshift $radikoj, $trovita;
        }
        push $lastaj, @$pliaj;
    }

    return $lastaj;
}

=item B<rangi_eblan_radikaron($ebla_radikaro)>

Redonas hakettabelon, kiu enhavas la C<$ebla_radikaro>n kaj rangon pri
ĝia verŝajneco.  Oni devas kompari rangojn nombre,
t.e. C<$rango1<$rango2>.

La algoritmo, per kiu la rangojn ĉi tiu subrutino komputas, estas tia:

    +1 se antaŭradiko estas antaŭ normala radiko
    +1 se postradiko estas post normala radiko
    -5 se radiko ne sciitas
    -n por n radikoj en ebla radikaro
    -1 se postradiko estas antaŭ normal radiko
    -1 se antaŭradiko estas post normala radiko
    -2 se postradiko estas antaŭ antaŭradiko

La hakettabelo redononta havas la formon:

    $hakettabelo1 = {
        rango => -2,
        ebla_radikaro => [
            am,
            uz
        ]
    };
    $hakettabelo2 = {
        rango => -1
        ebla_radikaro => [
            amuz
        ]
    };

=cut

sub rangi_eblan_radikaron {
    my $ebla_radikaro = shift
        || die "Neniu radikaro donita al „rangi_eblan_radikaron“";

    my $hakettabelo = {
        rango => -scalar(@$ebla_radikaro), # -n por n radikoj en ebla
        ebla_radikaro => $ebla_radikaro   # radikaro
    };

    # Unu el „antaŭ“, „normale“, „post“.
    my $antaŭa_radikloko = '';
    foreach my $radiko (@$ebla_radikaro) {
        my $nuna_radikloko = 'normale'; # samkiel la antaŭa_radikloko
        $nuna_radikloko = 'antaŭ' if ĉu_antaŭradiko($radiko);
        $nuna_radikloko = 'post'  if ĉu_postradiko($radiko);

        # -5 se radiko ne sciitas
        $hakettabelo->{'rango'} -= 5 unless ĉu_radiko($radiko);

        # +1 se antaŭradiko estas antaŭ normala radiko
        $hakettabelo->{'rango'} += 1
            if ($nuna_radikloko   eq 'normala' &&
                $antaŭa_radikloko eq 'antaŭ');
        # +1 se postradiko estas post normala radiko
        $hakettabelo->{'rango'} += 1
            if ($nuna_radikloko   eq 'post' &&
                $antaŭa_radikloko eq 'normale');
        # -1 se postradiko estas antaŭ normala radiko
        $hakettabelo->{'rango'} -= 1
            if ($nuna_radikloko   eq 'normale' &&
                $antaŭa_radikloko eq 'post');
        # -1 se antaŭradiko estas post normala radiko
        $hakettabelo->{'rango'} -= 1
            if ($nuna_radikloko   eq 'antaŭ' &&
                $antaŭa_radikloko eq 'normale');
        # -2 se antaŭradiko estas post normala radiko
        $hakettabelo->{'rango'} -= 2
            if ($nuna_radikloko   eq 'antaŭ' &&
                $antaŭa_radikloko eq 'post');
    }

    return $hakettabelo;
}

=item B<komputi_tipon_de_radikaro($ebla_radikaro)>

Redonas la tipon de la donita C<$ebla_radikaro> laŭ ĝiaj radikoj.

=cut

sub komputi_tipon_de_radikaro {
    my $ebla_radikaro = shift
        || die "Neniu radikaro dinita al „komputi_tipon_de_radikaro“";

    # Mi ne certas, ĉu tiu pravas.
    return $radikaro{$#$ebla_radikaro};
}

=back

=head1 BUGS

Jam sciitaj problemoj:

Ĉi tiu subrutinaro ne povas analizi vortojn, kiu enhavas nesciitajn
radikojn, inkluzive propajn nomojn.  Mi ne certas, kiel ĉi tiun
ripari.

Numerojn ĝi ne komprenas.  La numer-vortoj sciitas esti radikoj, sed
la postaj radikoj „opa“, „a“, ktp ne troviĝos.

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
