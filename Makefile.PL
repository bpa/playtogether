use 5.014002;
use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'Gamed',
    VERSION_FROM => 'lib/Gamed.pm',    # finds $VERSION
    PREREQ_PM    => {
        AnyEvent             => 0,
        'Authen::Passphrase' => 0,
        'Data::UUID'         => 0,
        DBI                  => 0,
        'DBD::SQLite'        => 0,
        EV                   => 0,
        JSON                 => 0,
        'Module::Refresh'    => 0,
        'Mojolicious::Lite'  => 0,
    },                                 # e.g., Module::Name => 1.1
    (
        $] >= 5.005
        ?                              ## Add these new keywords supported since 5.005
          (
            ABSTRACT => 'Modular HTML5 game server',
            AUTHOR   => 'Bruce Armstrong <bruce@fortressofgeekdom.org>'
          )
        : ()
    ),
);
