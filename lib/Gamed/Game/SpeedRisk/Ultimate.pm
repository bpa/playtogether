package Gamed::Game::SpeedRisk::Ultimate;

sub new {
    bless {
        'version'                => '0.1',
        'players'                => 12,
        'name'                   => 'UltimateRisk',
        'army_generation_period' => 45,
        'starting_armies'        => [ 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12 ],
        'continents'             => {
            'North America' => { 'regions' => [ '01', '03', '04' ] },
            'Europe'        => { 'regions' => [ 13,   14,   15, 16 ] },
            'South America' => { 'regions' => [ '05', '06', '07' ] },
            'Asia'          => { 'regions' => [ 17,   18,   19, 20, 21, 22, 23 ] },
            'Africa'        => { 'regions' => [ '09', 10, 11, 12 ] },
            'Pacific Isles' => { 'regions' => [ 24,   25, '00' ] },
            'Poles'         => { 'regions' => [ '02', '08' ] }
        },
        'regions' => {
            '11' => {
                'territories' => [ 110, 111, 112, 113, 114, 115 ],
                'bonus'       => 5
            },
            '21' => {
                'territories' => [ 210, 211, 212, 213 ],
                'bonus'       => 3
            },
            '05' => {
                'territories' => [ '050', '051', '052', '053' ],
                'bonus'       => 3
            },
            '17' => {
                'territories' => [ 170, 171, 172, 173, 174 ],
                'bonus'       => 4
            },
            '04' => {
                'territories' => [ '040', '041', '042', '043', '044' ],
                'bonus'       => 4
            },
            '02' => {
                'territories' => ['020'],
                'bonus'       => 2
            },
            '22' => {
                'territories' => [ 220, 221 ],
                'bonus'       => 2
            },
            '18' => {
                'territories' => [ 180, 181, 182, 183 ],
                'bonus'       => 3
            },
            '03' => {
                'territories' => [ '030', '031', '032', '033', '034' ],
                'bonus'       => 6
            },
            '08' => {
                'territories' => [ '080', '081', '082', '083' ],
                'bonus'       => 3
            },
            '23' => {
                'territories' => [ 230, 231, 232 ],
                'bonus'       => 3
            },
            '16' => {
                'territories' => [ 160, 161, 162, 163, 164 ],
                'bonus'       => 5
            },
            '13' => {
                'territories' => [ 130, 131, 132, 133, 134, 135, 136 ],
                'bonus'       => 6
            },
            '06' => {
                'territories' => [ '060', '061', '062', '063', '064' ],
                'bonus'       => 5
            },
            '25' => {
                'territories' => [ 250, 251, 252, 253, 254, 255 ],
                'bonus'       => 4
            },
            '01' => {
                'territories' => [ '010', '011', '012', '013', '014', '015' ],
                'bonus'       => 6
            },
            '12' => {
                'territories' => [ 120, 121, 122, 123, 124, 125, 126 ],
                'bonus'       => 6
            },
            '20' => {
                'territories' => [ 200, 201, 202, 203, 204, 205 ],
                'bonus'       => 4
            },
            '14' => {
                'territories' => [ 140, 141, 142 ],
                'bonus'       => 2
            },
            '15' => {
                'territories' => [ 150, 151, 152, 153, 154 ],
                'bonus'       => 5
            },
            '07' => {
                'territories' => [ '070', '071', '072', '073', '074', '075' ],
                'bonus'       => 4
            },
            '24' => {
                'territories' => [ 240, 241, 242, 243, 244, 245, 246 ],
                'bonus'       => 5
            },
            '00' => {
                'territories' => [ '000', '001', '002' ],
                'bonus'       => 2
            },
            '19' => {
                'territories' => [ 190, 191, 192, 193, 194, 195 ],
                'bonus'       => 6
            },
            '10' => {
                'territories' => [ 100, 101, 102, 103, 104 ],
                'bonus'       => 5
            },
            '09' => {
                'territories' => [ '090', '091', '092', '093', '094', '095' ],
                'bonus'       => 5
            }
        },
        'territories' => [
            {   'borders' => [ 246, '001' ],
                'name'    => '000'
            },
            {   'borders' => [ '000', '002' ],
                'name'    => '001'
            },
            {   'borders' => [ '001', 255 ],
                'name'    => '002'
            },
            {   'borders' => [ '035', '011', '013', '012' ],
                'name'    => '010'
            },
            {   'borders' => [ '020', '013', '010' ],
                'name'    => '011'
            },
            {   'borders' => [ '035', '010', '013', '031', '030' ],
                'name'    => '012'
            },
            {   'borders' => [ '010', '011', '014', '031' ],
                'name'    => '013'
            },
            {   'borders' => [ '015', '013' ],
                'name'    => '014'
            },
            {   'borders' => [ '020', '014' ],
                'name'    => '015'
            },
            {   'borders' => [ 191, 130, 131, '015', '011' ],
                'name'    => '020'
            },
            {   'borders' => [ '012', '031', '033' ],
                'name'    => '030'
            },
            {   'borders' => [ '012', '013', '032', '034', '033', '030' ],
                'name'    => '031'
            },
            {   'borders' => [ '031', '034' ],
                'name'    => '032'
            },
            {   'borders' => [ '030', '031', '034', '040' ],
                'name'    => '033'
            },
            {   'borders' => [ '032', '043', '033', '031' ],
                'name'    => '034'
            },
            {   'borders' => [ '010', '012', 192 ],
                'name'    => '035'
            },
            {   'borders' => [ '033', '041', 244 ],
                'name'    => '040'
            },
            {   'borders' => [ '040', '042' ],
                'name'    => '041'
            },
            {   'borders' => [ '041', '043', '051' ],
                'name'    => '042'
            },
            {   'borders' => [ '034', '044', '042' ],
                'name'    => '043'
            },
            {   'borders' => ['043'],
                'name'    => '044'
            },
            {   'borders' => [ '051', '060' ],
                'name'    => '050'
            },
            {   'borders' => [ '042', '052', '070', '060', '050' ],
                'name'    => '051'
            },
            {   'borders' => [ '053', '070', '051' ],
                'name'    => '052'
            },
            {   'borders' => ['052'],
                'name'    => '053'
            },
            {   'borders' => [ '050', '061' ],
                'name'    => '060'
            },
            {   'borders' => [ '070', '072', '063', '064', '062', '060' ],
                'name'    => '061'
            },
            {   'borders' => [ '061', '064' ],
                'name'    => '062'
            },
            {   'borders' => [ '061', '072', '064' ],
                'name'    => '063'
            },
            {   'borders' => [ '061', '063', '080', '062' ],
                'name'    => '064'
            },
            {   'borders' => [ '051', '052', '071', '072', '061' ],
                'name'    => '070'
            },
            {   'borders' => [ '070', '094', '073', '072' ],
                'name'    => '071'
            },
            {   'borders' => [ '070', '071', '073', '074', '063', '061' ],
                'name'    => '072'
            },
            {   'borders' => [ '071', '074', '072' ],
                'name'    => '073'
            },
            {   'borders' => [ '072', '073', '075' ],
                'name'    => '074'
            },
            {   'borders' => ['074'],
                'name'    => '075'
            },
            {   'borders' => [ '080', '081', '082', '083', '064' ],
                'name'    => '080'
            },
            {   'borders' => [ '080', '081', '082', '083', 126 ],
                'name'    => '081'
            },
            {   'borders' => [ '080', '081', '082', '083' ],
                'name'    => '082'
            },
            {   'borders' => [ '080', '081', '082', '083', 250 ],
                'name'    => '083'
            },
            {   'borders' => [ 133, '091', '092' ],
                'name'    => '090'
            },
            {   'borders' => [ 100, 101, '093', '092', '090' ],
                'name'    => '091'
            },
            {   'borders' => [ '090', '091', '093', '094' ],
                'name'    => '092'
            },
            {   'borders' => [ '091', '095', '094', '092' ],
                'name'    => '093'
            },
            {   'borders' => [ '092', '093', '095' ],
                'name'    => '094'
            },
            {   'borders' => [ '093', 103, '094' ],
                'name'    => '095'
            },
            {   'borders' => [ 110, 102, 101, '091' ],
                'name'    => 100
            },
            {   'borders' => [ '091', 100, 102, 103 ],
                'name'    => 101
            },
            {   'borders' => [ 100, 104, 103, 101 ],
                'name'    => 102
            },
            {   'borders' => [ 101, 102, 104, '095' ],
                'name'    => 103
            },
            {   'borders' => [ 102, 111, 121, 103 ],
                'name'    => 104
            },
            {   'borders' => [ 170, 111, 100 ],
                'name'    => 110
            },
            {   'borders' => [ 110, 112, 114, 104 ],
                'name'    => 111
            },
            {   'borders' => [ 111, 113, 114 ],
                'name'    => 112
            },
            {   'borders' => [ 173, 114, 112 ],
                'name'    => 113
            },
            {   'borders' => [ 111, 112, 113, 115 ],
                'name'    => 114
            },
            {   'borders' => [ 114, 123, 122, 120 ],
                'name'    => 115
            },
            {   'borders' => [ 115, 122, 121 ],
                'name'    => 120
            },
            {   'borders' => [ 104, 120, 122, 125 ],
                'name'    => 121
            },
            {   'borders' => [ 120, 115, 123, 126, 125, 121 ],
                'name'    => 122
            },
            {   'borders' => [ 115, 124, 126, 122 ],
                'name'    => 123
            },
            {   'borders' => [123],
                'name'    => 124
            },
            {   'borders' => [ 121, 122, 126 ],
                'name'    => 125
            },
            {   'borders' => [ 122, 123, '081', 125 ],
                'name'    => 126
            },
            {   'borders' => [ 140, 132, '020' ],
                'name'    => 130
            },
            {   'borders' => [ '020', 132 ],
                'name'    => 131
            },
            {   'borders' => [ 130, 134, 131 ],
                'name'    => 132
            },
            {   'borders' => [ 134, '090' ],
                'name'    => 133
            },
            {   'borders' => [ 132, 135, 136, 133 ],
                'name'    => 134
            },
            {   'borders' => [ 140, 150, 152, 136, 134 ],
                'name'    => 135
            },
            {   'borders' => [ 135, 134 ],
                'name'    => 136
            },
            {   'borders' => [ 160, 142, 141, 135, 130 ],
                'name'    => 140
            },
            {   'borders' => [ 140, 142 ],
                'name'    => 141
            },
            {   'borders' => [ 140, 160 ],
                'name'    => 142
            },
            {   'borders' => [ 151, 152, 135 ],
                'name'    => 150
            },
            {   'borders' => [ 150, 163, 164, 152 ],
                'name'    => 151
            },
            {   'borders' => [ 150, 151, 154, 153, 135 ],
                'name'    => 152
            },
            {   'borders' => [ 152, 154 ],
                'name'    => 153
            },
            {   'borders' => [ 164, 171, 170, 153, 152 ],
                'name'    => 154
            },
            {   'borders' => [ 161, 163, 142, 140 ],
                'name'    => 160
            },
            {   'borders' => [ 162, 163, 160 ],
                'name'    => 161
            },
            {   'borders' => [ 190, 180, 164, 163, 161 ],
                'name'    => 162
            },
            {   'borders' => [ 160, 161, 162, 164, 151 ],
                'name'    => 163
            },
            {   'borders' => [ 163, 162, 180, 171, 154, 151 ],
                'name'    => 164
            },
            {   'borders' => [ 154, 171, 172, 110 ],
                'name'    => 170
            },
            {   'borders' => [ 181, 182, 172, 170, 164 ],
                'name'    => 171
            },
            {   'borders' => [ 170, 171, 174, 173 ],
                'name'    => 172
            },
            {   'borders' => [ 172, 174, 113 ],
                'name'    => 173
            },
            {   'borders' => [ 172, 173 ],
                'name'    => 174
            },
            {   'borders' => [ 162, 190, 201, 183, 182, 181, 164 ],
                'name'    => 180
            },
            {   'borders' => [ 180, 182 ],
                'name'    => 181
            },
            {   'borders' => [ 181, 180, 183, 171 ],
                'name'    => 182
            },
            {   'borders' => [ 180, 210, 171, 182 ],
                'name'    => 183
            },
            {   'borders' => [ 191, 192, 180, 162 ],
                'name'    => 190
            },
            {   'borders' => [ '020', 193, 194, 192, 190 ],
                'name'    => 191
            },
            {   'borders' => [ 191, 194, 190 ],
                'name'    => 192
            },
            {   'borders' => [ '035', 195, 194, 191 ],
                'name'    => 193
            },
            {   'borders' => [ 191, 193, 195, 202 ],
                'name'    => 194
            },
            {   'borders' => [ 193, 221, 202, 194 ],
                'name'    => 195
            },
            {   'borders' => [ 202, 203, 201 ],
                'name'    => 200
            },
            {   'borders' => [ 200, 203, 204, 231, 180 ],
                'name'    => 201
            },
            {   'borders' => [ 194, 195, 220, 203, 200 ],
                'name'    => 202
            },
            {   'borders' => [ 200, 202, 205, 204, 201 ],
                'name'    => 203
            },
            {   'borders' => [ 201, 203, 232, 230, 213 ],
                'name'    => 204
            },
            {   'borders' => [203],
                'name'    => 205
            },
            {   'borders' => [ 183, 212, 213, 211 ],
                'name'    => 210
            },
            {   'borders' => [210],
                'name'    => 211
            },
            {   'borders' => [ 213, 210 ],
                'name'    => 212
            },
            {   'borders' => [ 201, 204, 230, 210, 212 ],
                'name'    => 213
            },
            {   'borders' => [ 202, 221 ],
                'name'    => 220
            },
            {   'borders' => [ 195, 220 ],
                'name'    => 221
            },
            {   'borders' => [ 213, 204, 232, 231 ],
                'name'    => 230
            },
            {   'borders' => [ 230, 232, 240 ],
                'name'    => 231
            },
            {   'borders' => [ 204, 231, 230 ],
                'name'    => 232
            },
            {   'borders' => [ 231, 244, 242, 241 ],
                'name'    => 240
            },
            {   'borders' => [ 240, 242, 250 ],
                'name'    => 241
            },
            {   'borders' => [ 240, 245, 243, 241 ],
                'name'    => 242
            },
            {   'borders' => [ 242, 246 ],
                'name'    => 243
            },
            {   'borders' => [ '040', 240 ],
                'name'    => 244
            },
            {   'borders' => [242],
                'name'    => 245
            },
            {   'borders' => [ '000', 252, 243 ],
                'name'    => 246
            },
            {   'borders' => [ 241, 251, 253, '083' ],
                'name'    => 250
            },
            {   'borders' => [ 252, 253, 250 ],
                'name'    => 251
            },
            {   'borders' => [ 246, 254, 253, 251 ],
                'name'    => 252
            },
            {   'borders' => [ 251, 252, 254, 255, 250 ],
                'name'    => 253
            },
            {   'borders' => [ 252, 255, 253 ],
                'name'    => 254
            },
            {   'borders' => [ 254, '002', 253 ],
                'name'    => 255
            }
        ],
      },
      shift;
}

1;