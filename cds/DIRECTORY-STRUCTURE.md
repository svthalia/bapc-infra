# CDS File structure

The CDS expects several files in specific directories to properly work:

For the contest-independent files, you can use the mounted 'present' folder:

present/
├── build
│   ├── logoA.png => Used in the logoA presentation
│   ├── logoB.png => Used in the logoB presentation
│   └── photo0.jpg => Used in the photo path presentation (use "photo" as presentation argument, or other argument for other files that match this path)
├── ccs
│   ├── primary.png => Used in the CCS presentation
│   └── shadow.png  => Used in the CCS presentation
├── photos => Used in the photos presentation
│   └── photo1.jpg
├── presentations-2.4.648.zip => Make sure this file matches the presentation client you want to use. After connecting, clients will update themselves to this version
└── promo => This folder can contain images that will be shown in the promo presentation


The contest specific files go in the contest data folder, as defined in cdsConfig.xml:

contest-data/
└── contestname
    ├── config
    │   ├── banner.png
    │   └── logo.png
    ├── organizations
    │   └── 1
    │       └── logo.png
    ├── submissions [...]
    └── teams
        └── 1
            └── photo.jpg


There is probably also support for team-photo overlays and such, check the latest documentation for this.

##### floor-map.tsv (not verified to work)
Several tools connected to the CDS can use a schematic of the floor map. For example, the presentation clients can display balloons travelling through the venue to a team desk. Also, the balloon utility uses thi>

The floor map can be configured by manually adding a file in the CDP at `<CDP>/config/floor-map.tsv`. The file should contain grid-based coordinates of all (team) desks, balloon stations, printers and aisle. Whe>

The first line of `floor-map.tsv` is expected to be in this form.

```
<team desk width>       <team desk depth>       <team area width>       <team area depth>
```
here the area of a team will be the whole rectangle for the team and the desk is the exact rectangle that will be drawn as desk. For correct visualization, it is best to just play around with these values a litt>
Note that for each team, 3 chairs will be drawn along the width of the desk but outside of the team area!

After the first line, all objects can be entered

- `team`: for each team, the file should contain a line in the form `team       <id>    <x>     <y>     <rotation>`. The `id` must correspond with the team id from domjudge (or, when using the CDP as data source>
- `balloon`: balloon stations can be drawn by entering lines in this form `balloon      <id>    <x>     <y>`. The `id` must correspond with the problem id.
- `printer`: printers can be added with this line: `printer     <x>     <y>`.
- `aisle`: aisles are used to display walking routes. They can be entered with `aisle   <x1>    <y1>    <x2>    <y2>`.

As an example, this file:

```tsv
12      3       12      4
team    <-1>    4       32      0
team    1       8       8       180
team    2       8       20      180
team    3       8       32      180
team    4       16      8       180
team    5       16      20      180
team    6       16      32      180
team    7       24      8       180
team    8       24      20      180
team    9       24      32      180
team    10      32      8       180
team    11      32      20      180
team    12      32      32      180
team    13      40      8       180
team    14      40      20      180
team    15      40      32      180
team    16      48      8       180
team    17      48      20      180
team    18      48      32      180
team    19      56      8       180
team    20      56      20      180
team    21      56      32      180
```

