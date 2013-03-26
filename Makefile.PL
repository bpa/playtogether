use 5.014002;
use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'Gamed',
    VERSION_FROM => 'lib/Gamed.pm',    # finds $VERSION
    PREREQ_PM    => {
        AnyEvent      => (),
        'Data::UUID'  => (),
        EV            => (),
        JSON          => (),
        'Set::Object' => (),
    },                                 # e.g., Module::Name => 1.1
    (   $] >= 5.005
        ?                              ## Add these new keywords supported since 5.005
          ( ABSTRACT_FROM => 'lib/Gamed.pm',            # retrieve abstract from module
            AUTHOR        => 'bruce <bruce@x-ray.at>'
          )
        : ()
    ),
);
