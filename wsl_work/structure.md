.
└── Base-V0
    ├── CITATION.cff                           # Citation metadata for academic references
    ├── CONTRIBUTING.md                        # Guidelines for contributing to the project
    ├── LICENSE                                # Software license terms
    ├── Makefile                               # Build automation script
    ├── PUBLICATIONS_USING_CHAMPSIM.bib       # Bibliography of research papers using ChampSim
    ├── README.md                              # Main project documentation and getting started guide
    ├── _configuration.mk                      # Build configuration settings (internal)
    ├── absolute.options                       # Compiler/linker options for absolute paths
    ├── bin
    │   └── champsim                          # Compiled ChampSim simulator executable
    │
    ├── branch                                 # Branch prediction algorithms
    │   ├── bimodal                           # Simple 2-bit saturating counter predictor
    │   │   ├── bimodal.cc                    # Implementation
    │   │   └── bimodal.h                     # Header file
    │   ├── gshare                            # Global history XOR-based predictor
    │   │   ├── gshare.cc
    │   │   └── gshare.h
    │   ├── hashed_perceptron                 # Neural network-based predictor
    │   │   ├── folded_shift_register.h       # History compression utility
    │   │   ├── hashed_perceptron.cc
    │   │   └── hashed_perceptron.h
    │   └── perceptron                        # Basic perceptron predictor
    │       ├── perceptron.cc
    │       └── perceptron.h
    │
    ├── btb                                   # Branch Target Buffer implementations
    │   └── basic_btb                         # Standard BTB with predictor components
    │       ├── basic_btb.cc                  # Main BTB logic
    │       ├── basic_btb.h
    │       ├── direct_predictor.cc           # Direct branch target prediction
    │       ├── direct_predictor.h
    │       ├── indirect_predictor.cc         # Indirect jump target prediction
    │       ├── indirect_predictor.h
    │       ├── return_stack.cc               # Return address stack for function calls
    │       └── return_stack.h
    │
    ├── champsim_config.json                   # Main simulator configuration file (architecture parameters)
    │
    ├── config                                 # Python configuration system
    │   ├── __init__.py                       # Package initialization
    │   ├── __pycache__                       # Python bytecode cache (generated)
    │   │   └── [various .pyc files]
    │   ├── compile_commands                  # Generates compile_commands.json for IDEs
    │   │   └── [Python modules for compilation database]
    │   ├── cxx.py                            # C++ compiler interface
    │   ├── defaults.py                       # Default configuration values
    │   ├── filewrite.py                      # Configuration file generation
    │   ├── instantiation_file.py             # C++ template instantiation generator
    │   ├── legacy.py                         # Legacy configuration format support
    │   ├── makefile.py                       # Makefile generation
    │   ├── modules.py                        # Module discovery and linking
    │   ├── parse.py                          # JSON configuration parser
    │   └── util.py                           # Utility functions
    │
    ├── config.sh                              # Shell script wrapper for configuration system
    │
    ├── docs                                   # Documentation source files (Sphinx/Doxygen)
    │   ├── Doxyfile                          # Doxygen configuration for API docs
    │   ├── README.txt                        # Documentation build instructions
    │   ├── _templates                        # Custom Sphinx templates
    │   │   └── other_branches.html
    │   ├── conf.py                           # Sphinx configuration
    │   ├── requirements.txt                  # Python dependencies for doc building
    │   └── src                               # reStructuredText documentation sources
    │       ├── Address-operations.rst        # Memory address manipulation guide
    │       ├── Bandwidth.rst                 # Bandwidth modeling documentation
    │       ├── Byte-sizes.rst                # Data size utilities
    │       ├── Cache-model.rst               # Cache hierarchy documentation
    │       ├── Configuration-API.rst         # JSON configuration format reference
    │       ├── Core-model.rst                # CPU core model documentation
    │       ├── Creating-a-configuration-file.rst  # Configuration tutorial
    │       ├── Legacy-modules.rst            # Backward compatibility guide
    │       ├── Module-support-library.rst    # Helper library documentation
    │       ├── Modules.rst                   # Module system overview
    │       ├── Publications-using-champsim.rst  # Research impact tracking
    │       └── index.rst                     # Documentation home page
    │
    ├── empty_file                             # Placeholder (possibly for testing)
    ├── global.options                         # Global compiler/linker flags
    │
    ├── inc                                    # Include directory (C++ header files)
    │   ├── access_type.h                     # Memory access type enumerations (READ/WRITE/PREFETCH)
    │   ├── address.h                         # Address manipulation classes
    │   ├── bandwidth.h                       # Bandwidth constraint modeling
    │   ├── block.h                           # Cache block/line representation
    │   ├── cache.h                           # Cache hierarchy base class
    │   ├── cache_builder.h                   # Cache instantiation from config
    │   ├── cache_stats.h                     # Cache statistics collection
    │   ├── champsim.h                        # Main simulator interface
    │   ├── channel.h                         # Communication channel abstraction
    │   ├── chrono.h                          # Timing and cycle counting
    │   ├── core_builder.h                    # CPU core instantiation
    │   ├── core_stats.h                      # Core performance statistics
    │   ├── deadlock.h                        # Deadlock detection utilities
    │   ├── defaults.hpp                      # Default parameter values
    │   ├── dram_controller.h                 # Memory controller interface
    │   ├── dram_stats.h                      # DRAM statistics
    │   ├── environment.h                     # Runtime environment settings
    │   ├── event_counter.h                   # Performance counter infrastructure
    │   ├── extent.h                          # Memory region representation
    │   ├── extent_set.h                      # Set of memory regions
    │   ├── inf_stream.h                      # Infinite stream abstraction (for traces)
    │   ├── instruction.h                     # Dynamic instruction representation
    │   ├── modules.h                         # Module plugin interface
    │   ├── msl                               # Module Support Library
    │   │   ├── bits.h                        # Bit manipulation utilities
    │   │   ├── fwcounter.h                   # Fixed-width counter
    │   │   └── lru_table.h                   # LRU replacement tracking table
    │   ├── ooo_cpu.h                         # Out-of-order CPU model
    │   ├── operable.h                        # Operable component base class (for cycle-by-cycle simulation)
    │   ├── phase_info.h                      # Simulation phase tracking
    │   ├── ptw.h                             # Page Table Walker
    │   ├── ptw_builder.h                     # PTW instantiation from config
    │   ├── register_allocator.h              # Register renaming/allocation
    │   ├── repeatable.h                      # Repeatable random number generation
    │   ├── stats_printer.h                   # Statistics output formatting
    │   ├── trace_instruction.h               # Trace file instruction format
    │   ├── tracereader.h                     # Trace file reader interface
    │   ├── util                              # General utility headers
    │   │   ├── algorithm.h                   # STL-style algorithms
    │   │   ├── bit_enum.h                    # Bitwise enum operations
    │   │   ├── bits.h                        # Bit field extraction
    │   │   ├── detect.h                      # Type trait detection
    │   │   ├── lru_table.h                   # Generic LRU table
    │   │   ├── ratio.h                       # Compile-time ratio arithmetic
    │   │   ├── span.h                        # Span (non-owning array view)
    │   │   ├── to_underlying.h               # Enum to integer conversion
    │   │   ├── type_traits.h                 # Custom type traits
    │   │   └── units.h                       # Physical unit types (bytes, cycles)
    │   ├── vmem.h                            # Virtual memory system
    │   └── waitable.h                        # Waiting/synchronization primitives
    │
    ├── module.options                         # Module-specific compiler options
    │
    ├── prefetcher                             # Hardware prefetcher implementations
    │   ├── ip_stride                         # Instruction Pointer-based stride prefetcher
    │   │   ├── ip_stride.cc                  # Detects constant stride patterns per PC
    │   │   └── ip_stride.h
    │   ├── next_line                         # Simple sequential prefetcher
    │   │   ├── next_line.cc                  # Prefetches next cache line
    │   │   └── next_line.h
    │   ├── no                                # Null prefetcher (disables prefetching)
    │   │   ├── no.cc
    │   │   └── no.h
    │   ├── spp_dev                           # Signature Path Prefetcher (research variant)
    │   │   ├── spp_dev.cc                    # Advanced pattern-based prefetcher
    │   │   └── spp_dev.h
    │   └── va_ampm_lite                      # Virtual Address Access Map Pattern Matching
    │       ├── va_ampm_lite.cc               # Lightweight pattern matching prefetcher
    │       └── va_ampm_lite.h
    │
    ├── replacement                            # Cache replacement policies
    │   ├── drrip                             # Dynamic Re-Reference Interval Prediction
    │   │   ├── drrip.cc                      # Adaptive between SRRIP and BRRIP
    │   │   └── drrip.h
    │   ├── lru                               # Least Recently Used
    │   │   ├── lru.cc                        # Traditional LRU implementation
    │   │   └── lru.h
    │   ├── random                            # Random replacement
    │   │   ├── random.cc                     # Uniform random victim selection
    │   │   └── random.h
    │   ├── ship                              # SHared Instruction Pointer
    │   │   ├── ship.cc                       # PC-based reuse prediction
    │   │   └── ship.h
    │   └── srrip                             # Static Re-Reference Interval Prediction
    │       ├── srrip.cc                      # Scan-resistant LRU variant
    │       └── srrip.h
    │
    ├── src                                    # Source implementation files
    │   ├── address.cc                        # Address manipulation implementation
    │   ├── bandwidth.cc                      # Bandwidth modeling logic
    │   ├── cache.cc                          # Cache hierarchy core logic
    │   ├── cache_stats.cc                    # Cache statistics collection
    │   ├── champsim.cc                       # Main simulator loop
    │   ├── channel.cc                        # Inter-component communication
    │   ├── chrono.cc                         # Timing infrastructure
    │   ├── core_stats.cc                     # CPU statistics
    │   ├── dram_controller.cc                # DRAM scheduling and timing
    │   ├── dram_stats.cc                     # Memory statistics
    │   ├── extent.cc                         # Memory region handling
    │   ├── generated_environment.cc          # Auto-generated build environment info
    │   ├── json_printer.cc                   # JSON output formatter
    │   ├── main.cc                           # Program entry point
    │   ├── modules.cc                        # Module loading system
    │   ├── ooo_cpu.cc                        # Out-of-order execution engine
    │   ├── operable.cc                       # Component scheduling
    │   ├── plain_printer.cc                  # Human-readable text output
    │   ├── ptw.cc                            # Page table walk implementation
    │   ├── ptw_builder.cc                    # PTW configuration
    │   ├── register_allocator.cc             # Register renaming logic
    │   ├── tracereader.cc                    # Trace file parsing
    │   └── vmem.cc                           # Virtual memory management
    │
    ├── test                                   # Test suite
    │   ├── config                            # Configuration file tests
    │   │   └── compile-only                  # Compilation verification tests
    │   │       └── [various .json test configs]
    │   ├── cpp                               # C++ unit tests
    │   │   ├── README.txt                    # Test suite documentation
    │   │   └── src                           # Test source files (using Catch2 framework)
    │   │       ├── 000-test-main.cc          # Test runner main
    │   │       ├── 001-operable.cc           # Component scheduling tests
    │   │       ├── 030-address-ops.cc        # Address manipulation tests
    │   │       ├── [100+ numbered test files]  # Comprehensive feature tests
    │   │       ├── instr.cc                  # Test instruction utilities
    │   │       ├── instr.h
    │   │       ├── matchers.hpp              # Custom Catch2 matchers
    │   │       ├── mocks.hpp                 # Mock objects for testing
    │   │       ├── pref_interface.h          # Prefetcher test interface
    │   │       └── repl_interface.h          # Replacement policy test interface
    │   ├── make                              # Test-specific Makefiles
    │   │   └── Makefile.test
    │   └── python                            # Python infrastructure tests
    │       ├── [test_*.py files]             # pytest test files
    │
    ├── tracer                                 # Instruction trace generation tools
    │   ├── README.md                         # Tracer usage documentation
    │   ├── cvp_converter                     # Championship Value Prediction trace converter
    │   │   ├── README.md
    │   │   └── cvp2champsim.cc               # Format conversion utility
    │   └── pin                               # Intel Pin-based tracer
    │       ├── Makefile                      # Pin tool build script
    │       ├── README.md                     # Pin tracer instructions
    │       └── champsim_tracer.cpp           # Dynamic binary instrumentation tracer
    │
    ├── vcpkg                                  # vcpkg package manager (empty, uses system)
    ├── vcpkg.json                            # Package dependency specification
    └── vcpkg_installed                       # Installed dependencies (C++ libraries)
        ├── vcpkg                             # vcpkg metadata
        │   ├── compiler-file-hash-cache.json # Build cache
        │   ├── info                          # Package installation manifests
        │   │   └── [package .list files]
        │   ├── manifest-info.json            # Dependency resolution info
        │   └── status                        # Installation status database
        └── x64-linux                         # Linux x86-64 architecture build
            ├── debug                         # Debug build artifacts
            │   └── lib                       # Debug libraries
            │       ├── [lib*.a files]        # Static libraries (CLI11, Catch2, fmt, etc.)
            │       └── pkgconfig             # pkg-config metadata files
            ├── include                       # Header files for all dependencies
            │   ├── CLI                       # CLI11 - command-line parser library
            │   ├── catch2                    # Catch2 - unit testing framework
            │   ├── fmt                       # fmt - formatting library (like C++20 std::format)
            │   ├── lzma                      # LZMA/XZ compression library
            │   ├── nlohmann                  # nlohmann/json - JSON parsing library
            │   ├── bzlib.h                   # bzip2 compression
            │   └── zlib.h                    # zlib compression
            ├── lib                           # Release build libraries
            │   ├── [lib*.a files]            # Optimized static libraries
            │   └── pkgconfig
            ├── share                         # Package metadata and CMake configs
            │   ├── [package-name dirs]       # CMake find_package() configuration files
            │   └── doc                       # Documentation for dependencies
            └── tools                         # Command-line tools from dependencies
                └── bzip2                     # bzip2 compression utilities