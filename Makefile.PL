use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'         => 'HTML::Ajax',
    'VERSION_FROM' => 'Ajax.pm',
    'PREREQ_PM'    => { Class::Accessor::Fast => 0 }
);
