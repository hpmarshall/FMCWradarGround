# FMCWradarGround — User's Guide

This repo processes ground-based FMCW (frequency-modulated continuous-wave) radar
data for snow/ice profiling. The core of the codebase is an object-oriented MATLAB
framework built around the class `FMCWprofile9` (the current version; `FMCWprofile8`
is the previous, still-used version). A radar processing session is represented by
one object, conventionally named `rd`, that owns raw/processed data plus five
"settings" sub-objects.

Top-level `process_*.m` scripts in the repo root are example, site-specific
processing pipelines built on top of this class. They are the best place to see the
class used end-to-end.

---

## 1. Repository layout

```
@FMCWprofile9/            current radar-profile class (methods as separate .m files)
@FMCWprofile8/             previous version (reads legacy .daq files directly)
@GPS/GPS.m                 GPS data/settings class
@measurement_settings/     hardware/measurement parameters
@processing_settings/      FFT / batching parameters
@postproc_settings/        filtering, gain, smoothing parameters
@skycalpause_settings/     sky-calibration & pause-removal parameters
@layerpick_settings/       surface/ground autopicking parameters
@data_settings/            empty placeholder (no classdef file present)
FMCWcodeNov2024/           field data-acquisition scripts (run on the instrument, not part of the OO processing pipeline)
process_*.m                example end-to-end processing scripts for specific field campaigns
ll2utm.m / utm2ll.m        lat/lon <-> UTM conversion (Beauducel implementation)
save_rd_to_mat.m, write_rd_to_netcdf.m   output helpers
radarFit.m, radarFit2.m, e_snowdry.m     depth-retrieval / validation helpers
```

In MATLAB, a folder named `@ClassName` is a *class folder*: `ClassName.m` inside it
is the `classdef`, and every other `.m` file in that folder is automatically a
method of the class, callable either as `obj = methodname(obj, ...)` or
`obj = obj.methodname(...)`.

---

## 2. Object model

`FMCWprofile9` (`@FMCWprofile9/FMCWprofile9.m:1`) aggregates five settings objects
plus the processed-data arrays:

| Property | Class | Purpose |
|---|---|---|
| `rd.M` | `measurement_settings` | hardware setup (frequency range, sample rate, PRF, antenna, GPS unit) |
| `rd.P` | `processing_settings` | FFT/processing parameters (frequency window, FFT size, batching, GPU/cores) |
| `rd.P2` | `postproc_settings` | median filter size, noise range, AGC window, smoothing grid |
| `rd.S` | `skycalpause_settings` | sky-calibration detection and pause removal |
| `rd.L` | `layerpick_settings` | surface/ground autopick thresholds |
| `rd.G` | `GPS` | raw GPS fixes + interpolation settings (`@GPS/GPS.m:1`) |

Main data properties of `rd` itself (`@FMCWprofile9/FMCWprofile9.m:18-32`):

| Property | Meaning |
|---|---|
| `PDATA` | frequency-domain power spectral density, one column per radar trace |
| `D` | complex FFT result before PSD estimation |
| `TWT` | two-way travel time vector (rows of `PDATA`/depth axis) |
| `TDATA` | time-domain data matrix (one column per trace) |
| `CPUtime` | absolute MATLAB `datenum` time of each radar trace (trace center) |
| `filenumber` | source `.daq`/data file number for each trace (used to match against GPS `daqfile`) |
| `xyz` | **the Nx3 [Easting, Northing, Elevation] matrix, one row per radar trace — the deliverable you asked about** |
| `FEFN` | false-easting/false-northing origin used for plotting |

Constructor: `rd = FMCWprofile9(location, data_dir)` (`@FMCWprofile9/FMCWprofile9.m:43-52`),
or simply `rd = FMCWprofile9` and set properties afterward.

---

## 3. Canonical end-to-end workflow

The cleanest illustration of the intended object-oriented workflow is
`process_RME_March2009_zigzag2.m:1`, using `FMCWprofile8` (which reads raw
National-Instruments `.daq` files):

```matlab
rd = FMCWprofile8;
rd.data_dir  = '.../REYNOLDS031909/';   % raw data location (trailing slash)
rd.proc_dir  = '.../PROC3/';            % where processed results are saved
rd.proc_subdir = 1;                     % which subdirectories (surveys) to process
rd.location  = 'RME';

rd = get_GPS_all(rd);   % (1) read & UTM-convert every GPS file under data_dir

rd.M.frange = [2 10];           % oscillator sweep range [GHz]
rd.P.files  = 1:500;            % which .daq files to process
rd.P.frange = [2.4 9.6];        % sub-band to actually process
rd.P.channel = 1;               % radar channel
rd.P.nfft = 2^14;
rd.P.batchsize = 50;
rd.P.ndaq = 500;
rd.P.maxP = rd.P.nfft/4;
rd.P.overwrite = 1;
rd.P2.MedFiltSize = [];
rd.P2.NoiseRange  = [];
rd.P2.gain_window = [];
rd.S.SkyCalRange = [];
rd.S.skythresh   = [];

rd = process_tdata_all(rd);     % (2) subdivide, FFT, sky-cal removal, save per-subdir .mat
```

`process_tdata_all` (`@FMCWprofile9/process_tdata_all.m:1`) internally, per
sub-directory, calls in order:

1. `subdivide_daq` — slices continuous voltage-ramp records into individual traces,
   producing `TDATA`, `CPUtime`, `filenumber` (`@FMCWprofile9/subdivide_daq.m:1`).
2. `cal_psd_radar` — Kaiser-Bessel windowed, zero-padded FFT → `PDATA`, `D`, `TWT`
   (`@FMCWprofile9/cal_psd_radar.m:1`).
3. `get_skycal` / `remove_skycal` — locate and strip sky-calibration/pause traces
   using total backscatter energy (`@FMCWprofile9/get_skycal.m:1`,
   `@FMCWprofile9/remove_skycal.m:1`).
4. Saves the resulting object as `rd` in `<proc_dir>/<subdir>.mat`.

**Update:** as of this revision, `process_tdata_all` now calls `get_xyz_radar`
automatically (guarded by `~isempty(obj.G.xyz)`) at the same point where it was
previously commented out, and `@FMCWprofile9/subdivide_daq.m` now populates
`obj.filenumber` (mirroring `@FMCWprofile8/subdivide_daq.m:37,63,68`), so `rd.xyz`
is built as part of the standard pipeline once `rd.G` has been populated via
`get_GPS`/`get_GPS_all` beforehand. See §4 for how the interpolation itself works,
and §5 for the second GPS source format this also required handling.

Once processed, use `plot_image`, `pick_surface`, `pick_ground`,
`filter_normalize`, `range_gain`, `smooth_image`, `get_equal_spaced`, or the
`LayerPicker4` GUI for further analysis (see §6).

---

## 4. GPS interpolation to build `rd.xyz` (Nx3)

This is the specific mechanism you asked about. It happens in three stages,
spread across three methods, all under `@FMCWprofile9/` (identical logic exists
under `@FMCWprofile8/`).

### 4.1 Reading raw GPS fixes — `get_GPS` / `get_GPS_all`

`get_GPS` (`@FMCWprofile9/get_GPS.m:1`) reads the GPS log file (`G*.txt`) found in
`rd.data_dir`. Each line is expected to contain a GGA sentence (`$GPGGA`/`$GNGGA`),
in either of two forms, auto-detected by regex (`get_GPS.m:20-27`):

- **`<filenumber>,$GPGGA,...`** — written by the onboard acquisition GPS logger
  (`FMCWcodeNov2024/profile_6-18_2diskGPS_v3.m:108-129` and similar scripts write
  exactly this to `GPSdata.txt`, tagging each fix with the radar file/trace-batch
  counter it was recorded alongside).
- **bare `$GPGGA,...`** — from a standalone GPS receiver not wired into the radar's
  acquisition loop (e.g. a "Geode" logger, as used for `process_GM2020.m` and
  `process_Utqiagvik2024b.m`), which has no notion of the radar's file numbering.

Both are parsed with the same fixed-field `textscan` (`get_GPS.m:22-27`) into:
daqfile number (`NaN` for the bare form), lat, lon, elevation, satellite count,
HDOP, and fix quality. It then:

- Converts sexagesimal lat/lon strings to decimal degrees (`get_GPS.m:33-48`).
- Converts to UTM with `ll2utm` (`get_GPS.m:57`, see `ll2utm.m:1`).
- Builds a GPS `datenum` time for every fix from the message's HHMMSS field plus
  `rd.date` (`get_GPS.m:61-66`).
- Populates the `GPS` object (`rd.G`): `xyz` (UTM E, N, elev), `time`, `daqfile`,
  `NumSat`, `HDOP`, `Fix` (`get_GPS.m:83-90`).

`get_GPS_all` (`@FMCWprofile9/get_GPS_all.m:1`) is the multi-directory wrapper —
it loops over every subdirectory in `rd.subdir`, runs `get_GPS` in each, and
caches the result as `GPS_all.mat` in `proc_dir` so it isn't re-parsed on rerun
(`get_GPS_all.m:6-28`). This is what you normally call (as in §3, step 1).

### 4.2 Matching a GPS time to a radar time

Two clocks have to be reconciled: GPS fixes have GPS-derived UTC-ish time
(`rd.G.time`), and radar traces have the DAQ computer's clock time
(`rd.CPUtime`, set per-trace at the trace midpoint in `subdivide_daq.m:48`).
These two clocks are not necessarily identical, so where possible the code avoids
interpolating GPS position directly against GPS time. `get_xyz_radar` now handles
two cases per GPS fix (`@FMCWprofile9/get_xyz_radar.m:22-30`):

- **Fix has a `daqfile` number** (onboard-logger form, §4.1): find all radar traces
  from that same file (via `obj.filenumber`), and take the **radar CPU time of the
  first trace in that file** as the trusted time anchor for that GPS position —
  this sidesteps clock differences entirely, since both ends of the comparison are
  ultimately expressed in the radar's own clock:

  ```matlab
  DF = obj.G.daqfile(n);              % daqfile this GPS fix belongs to
  I3 = obj.filenumber == DF;          % all radar traces from that file
  RT(n) = min(obj.CPUtime(I3));       % radar CPU time of first trace in that file
  ```

  This is why `obj.filenumber` (populated in `subdivide_daq`, see §3) matters for
  this branch.

- **Fix has no `daqfile` number** (bare/standalone-logger form, §4.1): there is no
  file to match against, so the fix's own GPS timestamp is used directly, shifted
  by `rd.G.UTCoffset` hours to align the DAQ computer's clock with GPS UTC time
  (`@GPS/GPS.m` — set this per site/timezone if you use a standalone logger; it
  defaults to 0):

  ```matlab
  RT(n) = obj.G.time(n) - obj.G.UTCoffset/24;
  ```

### 4.3 The actual interpolation — `get_xyz_radar`

`get_xyz_radar` (`@FMCWprofile9/get_xyz_radar.m:1`) is the method that produces
`rd.xyz`. Step by step:

1. **Quality filter each GPS fix** (`get_xyz_radar.m:12-27`), keeping only fixes
   that are:
   - not within `rd.G.dtSkyCal` seconds (default 5 s) of a known sky-calibration
     trace (`rd.S.SkycalTraces`, populated earlier by `get_skycal`), and
   - have `HDOP < rd.G.maxHDOP` (default 2), and
   - have finite `x,y,z`.

   Each surviving fix is paired with a radar time `RT` via the file-number match
   described in §4.2.

2. **Drop fixes without a usable radar time**, and restrict to the requested set
   of traces (`rd.S.ProfileTraces` if sky-cal has been located, else all traces)
   (`get_xyz_radar.m:29-35`).

3. **Discard radar traces outside the GPS time bracket** — any trace whose time
   falls before the first or after the last good GPS fix cannot be interpolated
   and is set to `NaN` (`get_xyz_radar.m:37-40`).

4. **Interpolate.** For traces within the bracket, cubic Hermite interpolation
   (`pchip`) is applied independently to each coordinate, radar-trace-time against
   GPS-fix-time (`get_xyz_radar.m:45-50`):

   ```matlab
   Rx2 = pchip(RT, XYZ(:,1), RT2(I3));   % Easting
   Ry2 = pchip(RT, XYZ(:,2), RT2(I3));   % Northing
   Rz2 = pchip(RT, XYZ(:,3), RT2(I3));   % Elevation
   ```

   `RT` = radar-anchored time of each good GPS fix; `RT2(I3)` = `CPUtime` of every
   radar trace to be located. `pchip` (rather than linear `interp1`) is used
   because it avoids overshoot while still tracking curvature in the GPS track,
   which matters for the tight turns typical of survey zig-zags/loops.

5. **Store the result**: `obj.xyz = [Rx(:) Ry(:) Rz(:)]` (`get_xyz_radar.m:51`) —
   an Nx3 matrix, one row per radar trace, `NaN` where no valid interpolation was
   possible.

Minimal usage:

```matlab
rd = get_GPS_all(rd);        % or get_GPS(rd) for a single directory - populates rd.G
rd = process_tdata_all(rd);  % populates PDATA, CPUtime, filenumber, S.SkycalTraces,
                              % and now also calls get_xyz_radar internally -> rd.xyz
```

`get_xyz_radar` is a normal method too, so you can also call it directly
(e.g. to rebuild `rd.xyz` after changing `rd.G.maxHDOP` or `rd.S.SkycalTraces`
without reprocessing everything): `rd = get_xyz_radar(rd);`

Quick sanity check/plot: `rd.plot_xyz` overlays the raw GPS track (circles)
against the interpolated per-trace positions (red x's)
(`@FMCWprofile9/FMCWprofile9.m:98-108`).

---

## 5. Older manual geolocation still present in some field scripts

The example scripts `process_Utqiagvik2024b.m:47-68` and
`process_GM2020.m:97-127` predate the `get_GPS`/`get_xyz_radar` fixes above and
do the GPS-to-trace interpolation by hand instead, because they use a **standalone
GPS receiver** ("Geode") that isn't wired into the radar's acquisition loop and so
writes bare `$GPGGA` sentences with no per-fix daqfile tag — the same case now
handled by `get_xyz_radar`'s fallback branch (§4.2):

```matlab
D = readtable(gpsdatafile, 'ReadVariableNames', false);
Ix = find(startsWith(string(D.Var1), '$GPGGA'));
% ... parse lat/lon/UTC out of each $GPGGA sentence ...
[x, y, zone] = ll2utm(lat, lon);
Rx = interp1(UTC, x, CPUtime);   % linear interpolation, GPS time -> radar CPUtime
Ry = interp1(UTC, y, CPUtime);
```

This still works and these scripts don't need to be changed, but it's now
redundant with the class pipeline: `get_GPS`/`get_xyz_radar` handle this exact
GPS source natively (§4.1–§4.2), additionally give you HDOP/sky-cal-aware
filtering, `pchip` (not linear) interpolation, elevation, and assemble the result
directly into `rd.xyz` (Nx3) rather than separate `Rx`/`Ry` vectors. To switch a
script like this over: point `rd.data_dir` at a folder containing the Geode `.txt`
log (named so it matches `get_GPS`'s `G*.txt` search, e.g. rename/copy it), set
`rd.G.UTCoffset` to the same hour offset these scripts apply manually
(`process_Utqiagvik2024b.m:37` uses `+6/24`, `process_GM2020.m:79` uses `+7/24`),
then call `rd = get_GPS(rd)` (or `get_GPS_all`) before `process_tdata_all`/
`get_xyz_radar`.

---

## 6. Post-processing methods

All are `FMCWprofile9` methods (`obj = method(obj)` pattern), typically applied
after `process_tdata_all`/`get_xyz_radar`:

| Method | File | Purpose |
|---|---|---|
| `filter_normalize` | `@FMCWprofile9/filter_normalize.m:1` | median filter (`P2.MedFiltSize`) + normalize to near-field noise level (`P2.NoiseRange`) |
| `range_gain` | `@FMCWprofile9/range_gain.m:1` | automatic gain control — subtracts a smoothed 2.5th-percentile noise floor per row |
| `pick_surface` | `@FMCWprofile9/pick_surface.m:1` | autopicks the first peak above `L.surfthresh` within `[L.DCcoupling, L.SurfMax]` per trace |
| `pick_ground` | `@FMCWprofile9/pick_ground.m:1` | smooths with a bi-square kernel, autopicks deepest peak above `L.Gthresh` above index `L.Gmin` |
| `smooth_image` | `@FMCWprofile9/smooth_image.m:1` | resamples `PDATA` onto an equally spaced spatial grid (`P2.smooth_x/y`, `P2.smooth_window`) via distance-weighted (bi-square) averaging |
| `get_equal_spaced` | `@FMCWprofile9/get_equal_spaced.m:1` | generates the equally-spaced `(smooth_x, smooth_y)` grid along the GPS track for use by `smooth_image` |
| `LayerPicker4` | `@FMCWprofile9/LayerPicker4.m:1` | GUIDE-based interactive GUI for manual layer picking |

## 7. Output

- `save_rd_to_mat.m:1` — loads a saved `rd` and re-saves `PDATA`, `TWT`, and
  (if present) `x/y/z` split out of `rd.xyz`, plus sky-cal/profile trace indices,
  as a flat `.mat`.
- `write_rd_to_netcdf.m:1` — same idea, written to NetCDF (`PDATA`, `TWT`,
  `x`, `y`, `z`, `skycal_idx`, `trace_idx`).
- `radarFit.m` / `radarFit2.m` — compare autopicked/derived radar depths against
  independent ground-truth (e.g., MagnaProbe) depths; `radarFit2` additionally
  returns RMSE and correlation.
- `e_snowdry.m` — dry-snow dielectric permittivity model, used to convert TWT to
  depth (density → velocity).

---

## 8. Practical gotchas found while reading the code

- `README.md` is essentially empty — this guide is the closest thing to
  documentation in the repo.
- `get_xyz_radar` now runs automatically inside `process_tdata_all` whenever
  `rd.G.xyz` is non-empty (§3); if you see "No GPS data loaded (obj.G.xyz empty)
  - skipping xyz interpolation" in the console, it means `get_GPS`/`get_GPS_all`
  wasn't run first, or found no GPS file/fixes in `rd.data_dir`.
- `get_GPS` auto-detects both the onboard-logger (`<filenumber>,$GPGGA,...`) and
  standalone-logger (bare `$GPGGA,...`) line formats (§4.1). For the standalone
  case, set `rd.G.UTCoffset` to align GPS UTC time with the DAQ computer's clock
  (§4.2, §5) — this can't be auto-detected and defaults to 0.
- `@data_settings/` is an empty class folder (no `classdef` file) — currently
  unused; ignore it.
- Several `.m~`/`.asv` autosave/backup files are checked into the
  `@FMCWprofile*` folders (e.g. `FMCWprofile7.m~`); they are not live class
  methods, just editor backups.
- `plot_xyz`/`get_GPS`/`get_GPS_all` all call `figure(...)` and plot — expect
  pop-up figures when running these interactively.
