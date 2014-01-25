package Gamed::Game::SpeedRisk::Classic;

sub new {
    bless {
        'version'                => '0.3',
        'players'                => 6,
        'name'                   => 'SpeedRisk',
        'army_generation_period' => 25,
        'starting_armies' => [ 0, 0, 26, 21, 19, 16, 13 ],
        'continents' => {
            'Australia' => {
                'territories' => [
                    'New Guinea',
                    'Indonesia',
                    'Western Australia',
                    'Eastern Australia'
                ],
                'bonus' => 2
            },
            'Europe' => {
                'territories' => [
                    'Iceland',
                    'Southern Europe',
                    'Ukraine',
                    'Scandinavia',
                    'Great Britain',
                    'Western Europe',
                    'Northern Europe'
                ],
                'bonus' => 5
            },
            'North America' => {
                'territories' => [
                    'Eastern US',      'Northwest Territory',
                    'Western US',      'Ontario',
                    'Central America', 'Alberta',
                    'Greenland',       'Alaska',
                    'Quebec'
                ],
                'bonus' => 5
            },
            'South America' => {
                'territories' => [ 'Brazil', 'Venezuela', 'Argentina', 'Peru' ],
                'bonus'       => 2
            },
            'Asia' => {
                'territories' => [
                    'Afghanistan', 'Mongolia', 'Ural',      'Japan',
                    'Irkutsk',     'India',    'Siam',      'Yakutsk',
                    'Siberia',     'China',    'Kamchatka', 'Middle East'
                ],
                'bonus' => 7
            },
            'Africa' => {
                'territories' => [
                    'Egypt',       'Congo', 'Madagascar', 'South Africa',
                    'East Africa', 'North Africa'
                ],
                'bonus' => 3
            }
        },
        'territories'     => [
            {   'borders' => [ 'Central America' ],
                'name'    => 'Eastern US'
            },
            {   'borders' => [ 'Alberta', 'Greenland', 'Ontario' ],
                'name'    => 'Northwest Territory'
            },
            {   'borders' => [ 'Eastern US', 'Central America' ],
                'name'    => 'Western US'
            },
            {   'borders' => [ 'Quebec', 'Eastern US', 'Western US' ],
                'name'    => 'Ontario'
            },
            {   'borders' => [ 'Venezuela' ],
                'name'    => 'Central America'
            },
            {   'borders' => [ 'Ontario', 'Western US' ],
                'name'    => 'Alberta'
            },
            {   'borders' => [ 'Iceland', 'Quebec', 'Ontario' ],
                'name'    => 'Greenland'
            },
            {   'borders' => [ 'Kamchatka', 'Northwest Territory', 'Alberta' ],
                'name'    => 'Alaska'
            },
            {   'borders' => [ 'Eastern US' ],
                'name'    => 'Quebec'
            },
            {   'borders' => [ 'North Africa', 'Argentina' ],
                'name'    => 'Brazil'
            },
            {   'borders' => [ 'Brazil', 'Peru' ],
                'name'    => 'Venezuela'
            },
            { 'name' => 'Argentina' },
            {   'borders' => [ 'Brazil', 'Argentina' ],
                'name'    => 'Peru'
            },
            {   'borders' => [ 'Scandinavia', 'Great Britain' ],
                'name'    => 'Iceland'
            },
            {   'borders' => [ 'Middle East', 'Egypt', 'North Africa' ],
                'name'    => 'Southern Europe'
            },
            {
                'borders' => [
                    'Ural',
                    'Afghanistan',
                    'Middle East',
                    'Southern Europe',
                    'Northern Europe'
                ],
                'name' => 'Ukraine'
            },
            {   'borders' => [ 'Ukraine', 'Northern Europe', 'Great Britain' ],
                'name'    => 'Scandinavia'
            },
            {   'borders' => [ 'Northern Europe', 'Western Europe' ],
                'name'    => 'Great Britain'
            },
            {   'borders' => [ 'Southern Europe', 'North Africa' ],
                'name'    => 'Western Europe'
            },
            {   'borders' => [ 'Southern Europe', 'Western Europe' ],
                'name'    => 'Northern Europe'
            },
            {   'borders' => [ 'Middle East', 'East Africa' ],
                'name'    => 'Egypt'
            },
            {   'borders' => [ 'South Africa' ],
                'name'    => 'Congo'
            },
            { 'name' => 'Madagascar' },
            {   'borders' => [ 'Madagascar' ],
                'name'    => 'South Africa'
            },
            {   'borders' =>
                  [ 'Middle East', 'Madagascar', 'South Africa', 'Congo' ],
                'name' => 'East Africa'
            },
            {   'borders' => [ 'Egypt', 'East Africa', 'Congo' ],
                'name'    => 'North Africa'
            },
            {   'borders' => [ 'China', 'India', 'Middle East' ],
                'name'    => 'Afghanistan'
            },
            {   'borders' => [ 'Japan', 'China' ],
                'name'    => 'Mongolia'
            },
            {   'borders' => [ 'Siberia', 'China', 'Afghanistan' ],
                'name'    => 'Ural'
            },
            { 'name' => 'Japan' },
            {   'borders' => [ 'Mongolia' ],
                'name'    => 'Irkutsk'
            },
            {   'borders' => [ 'Siam' ],
                'name'    => 'India'
            },
            {   'borders' => [ 'Indonesia' ],
                'name'    => 'Siam'
            },
            {   'borders' => [ 'Kamchatka', 'Irkutsk' ],
                'name'    => 'Yakutsk'
            },
            {   'borders' => [ 'Yakutsk', 'Irkutsk', 'Mongolia', 'China' ],
                'name'    => 'Siberia'
            },
            {   'borders' => [ 'India', 'Siam' ],
                'name'    => 'China'
            },
            {   'borders' => [ 'Japan', 'Mongolia', 'Irkutsk' ],
                'name'    => 'Kamchatka'
            },
            {   'borders' => [ 'India' ],
                'name'    => 'Middle East'
            },
            {   'borders' => [ 'Western Australia', 'Eastern Australia' ],
                'name'    => 'New Guinea'
            },
            {   'borders' => [ 'New Guinea', 'Western Australia' ],
                'name'    => 'Indonesia'
            },
            {   'borders' => [ 'Eastern Australia' ],
                'name'    => 'Western Australia'
            },
            { 'name' => 'Eastern Australia' }
        ],
      },
      shift;
}

1;
