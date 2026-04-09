set(GIT_VERSION_FILE "${OUTPUT_DIR}/git-version.cpp")
set(GIT_VERSION "unknown")
set(GIT_VERSION_UPDATE "1")
set(GENERATE_WIN_VERSION "${GENERATE_WIN_VERSION}")

find_package(Git)
if(GIT_FOUND AND EXISTS "${SOURCE_DIR}/.git/")
	execute_process(COMMAND ${GIT_EXECUTABLE} describe --always
		WORKING_DIRECTORY ${SOURCE_DIR}
		RESULT_VARIABLE exit_code
		OUTPUT_VARIABLE GIT_VERSION)
	if(NOT ${exit_code} EQUAL 0)
		message(WARNING "git describe failed, unable to include version.")
	endif()
	string(STRIP ${GIT_VERSION} GIT_VERSION)
else()
	message(WARNING "git not found, unable to include version.")
endif()

if(EXISTS ${GIT_VERSION_FILE})
	# Don't update if marked not to update.
	file(STRINGS ${GIT_VERSION_FILE} match
		REGEX "PPSSPP_GIT_VERSION_NO_UPDATE 1")
	if(NOT ${match} EQUAL "")
		set(GIT_VERSION_UPDATE "0")
	endif()

	# Let's also skip if it's the same.
	string(REPLACE "." "\\." GIT_VERSION_ESCAPED ${GIT_VERSION})
	file(STRINGS ${GIT_VERSION_FILE} match
		REGEX "PPSSPP_GIT_VERSION = \"${GIT_VERSION_ESCAPED}\";")
	if(NOT ${match} EQUAL "")
		set(GIT_VERSION_UPDATE "0")
	endif()
endif()

set(code_string "// This is a generated file.\n\n"
	"const char *PPSSPP_GIT_VERSION = \"${GIT_VERSION}\"\;\n\n"
	"// If you don't want this file to update/recompile, change to 1.\n"
	"#define PPSSPP_GIT_VERSION_NO_UPDATE 0\n")

if ("${GIT_VERSION_UPDATE}" EQUAL "1")
	file(WRITE ${GIT_VERSION_FILE} ${code_string})
endif()

if("${GENERATE_WIN_VERSION}" STREQUAL "1")
	set(WIN_VERSION_FILE "${SOURCE_DIR}/Windows/win-version.h")

	if("${GIT_VERSION}" MATCHES "^v([0-9]+\\.[0-9]+\\.[0-9]+)(-([0-9]+))?")
		set(WIN_RELEASE_VERSION "${CMAKE_MATCH_1}")
		set(WIN_BUILD_NUMBER "0")
		if(NOT "${CMAKE_MATCH_3}" STREQUAL "")
			set(WIN_BUILD_NUMBER "${CMAKE_MATCH_3}")
		endif()
		string(REPLACE "." "," WIN_VERSION_COMMA "${WIN_RELEASE_VERSION}")
		set(WIN_VERSION_COMMA "${WIN_VERSION_COMMA},${WIN_BUILD_NUMBER}")
	else()
		set(GIT_VERSION_PADDED "${GIT_VERSION}00000000")
		string(SUBSTRING "${GIT_VERSION_PADDED}" 0 4 WIN_VERSION_PART1)
		string(SUBSTRING "${GIT_VERSION_PADDED}" 4 4 WIN_VERSION_PART2)
		set(WIN_VERSION_COMMA "0,0,0x${WIN_VERSION_PART1},0x${WIN_VERSION_PART2}")
	endif()

	set(win_code_string "// This is a generated file.\n"
		"// GIT_VERSION=${GIT_VERSION}\n\n"
		"#define PPSSPP_WIN_VERSION_STRING \"${GIT_VERSION}\"\n"
		"#define PPSSPP_WIN_VERSION_COMMA ${WIN_VERSION_COMMA}\n\n"
		"// If you don't want this file to update/recompile, change to 1.\n"
		"#define PPSSPP_WIN_VERSION_NO_UPDATE 0\n")

	file(WRITE ${WIN_VERSION_FILE} ${win_code_string})
endif()
