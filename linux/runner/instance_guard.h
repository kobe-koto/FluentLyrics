#ifndef FLUTTER_RUNNER_INSTANCE_GUARD_H_
#define FLUTTER_RUNNER_INSTANCE_GUARD_H_

#include <string>

// Ensures an older Fluent Lyrics process from a different executable is gone
// before this process registers the GtkApplication bus name.
//
// Returns true when startup can continue. If false is returned, |error| holds
// a user-facing diagnostic suitable for stderr / g_warning.
bool fluent_lyrics_prepare_instance(std::string *error);

#endif // FLUTTER_RUNNER_INSTANCE_GUARD_H_
