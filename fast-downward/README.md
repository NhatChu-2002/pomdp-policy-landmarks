# Fast Downward (modified)

A copy of the Fast Downward planner (http://www.fast-downward.org), used only
for its RHW landmark generator. Two source changes, both in
`src/search/landmarks/`:

| File | Change | Why |
|---|---|---|
| `landmark_factory.cc` | `exit(0)` right after the landmark graph is printed | explanation needs no search; use `astar(blind())` to get a plan |
| `landmark_factory_rpg_sasp.cc` | disjunctive landmarks kept up to 64 facts (stock: 4) | Mine grids beyond 2x2 need 9- to 64-value belief disjunctions |

The binary lives in `builds/release64/bin/downward.exe` (not versioned).
`builds/release64/bin/downward_stock_cap4.exe` is the build before the second
change.

## Rebuilding one changed file (Windows, MSYS2 g++)

`cmake`/`nmake` are not on PATH here, so recompile the object and relink by
hand from `builds/release64/search`:

```bash
G=/c/msys64/mingw64/bin
SRC=<repo>/fast-downward/src/search
$G/g++.exe -m64 -std=c++11 -g -Wall -Wextra -pedantic -O3 -DNDEBUG -fomit-frame-pointer \
  -I"$SRC/ext" -o CMakeFiles/downward.dir/landmarks/<file>.cc.obj -c "$SRC/landmarks/<file>.cc"
rm -f CMakeFiles/downward.dir/objects.a
$G/ar.exe qc CMakeFiles/downward.dir/objects.a @CMakeFiles/downward.dir/objects1.rsp
$G/g++.exe -m64 -O3 -Wl,--whole-archive CMakeFiles/downward.dir/objects.a \
  -Wl,--no-whole-archive -o ../bin/downward.exe @CMakeFiles/downward.dir/linkLibs.rsp
```

A full build uses the stock `python build.py release64` (needs CMake).
