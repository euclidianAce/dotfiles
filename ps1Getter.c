#include <assert.h>
#include <stdarg.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <sys/ioctl.h>
#include <time.h>
#include <unistd.h>

#define ESC "\033["

#define LINE_HORIZONTAL "─"
#define LINE_VERTICAL "│"
#define CORNER_TOP_LEFT "┌"
#define CORNER_TOP_RIGHT "┐"
#define CORNER_BOTTOM_LEFT "└"
#define CORNER_BOTTOM_RIGHT "┘"
#define T_UP "┴"
#define T_DOWN "┬"
#define T_LEFT "┤"
#define T_RIGHT "├"

typedef enum {
	ANSI_NONE = 0,
	ANSI_BOLD,

	ANSI_RED = 31,
	ANSI_GREEN,
	ANSI_YELLOW,
	ANSI_BLUE,
	ANSI_MAGENTA,
	ANSI_CYAN,
	ANSI_GRAY,

	ANSI_BRIGHT_RED = 91,
	ANSI_BRIGHT_GREEN,
	ANSI_BRIGHT_YELLOW,
	ANSI_BRIGHT_BLUE,
	ANSI_BRIGHT_MAGENTA,
	ANSI_BRIGHT_CYAN,
	ANSI_BRIGHT_GRAY,
} Ansi_Color;

#define MAX_COMPONENT_LENGTH 128

typedef struct {
	Ansi_Color color;
	size_t len;
	char data[MAX_COMPONENT_LENGTH];
} Component;

#ifdef BASH
#define CMP_FMT "\\[" ESC "%dm\\]%.*s\\[" ESC "0m\\]"
#else
#define CMP_FMT ESC "%dm%.*s" ESC "0m"
#endif
#define CMP_ARG(cmp) (int)(cmp).color, (int)(cmp).len, (cmp).data

static size_t sprintf_component(Component *comp, const char *fmt, ...) {
	va_list args;
	va_start(args, fmt);
	comp->len = vsnprintf(comp->data, MAX_COMPONENT_LENGTH, fmt, args);
	va_end(args);
	return comp->len;
}

static inline size_t sz_min(size_t a, size_t b) { return a < b ? a : b; }

static inline void strcpy_component(Component *comp, const char *src) {
	size_t len = sz_min(strlen(src), MAX_COMPONENT_LENGTH);
	memcpy(comp->data, src, len);
	comp->len = len;
}

static inline void put_color(Ansi_Color col) {
#ifdef BASH
	printf("\\[" ESC "%dm\\]", col);
#else
	printf(ESC "%dm", col);
#endif
}

static void setup_time_component(void);
static void setup_username_component(void);
static void setup_cwd_component(void);
static void setup_git_branch_component(void);
static const char *username;

static Ansi_Color line_color = ANSI_CYAN;
static size_t num_components = 0;
static Component components[32] = {0};
static inline Component *next_component(void) { return &components[num_components++]; }
static struct winsize w;

#define FOR_EACH_COMPONENT(current_idx, name, body) do { \
		size_t current_idx = 0; \
		for (Component *name = &components[0]; \
			current_idx < num_components; \
			name = &components[++current_idx]) \
		{ body } \
	} while (0)

static size_t compute_length(void) {
	size_t result = 0;
	FOR_EACH_COMPONENT(i, comp, {
		result += comp->len;
	});
	return result;
}

int main(void) {
	username = getenv("USER");
	if (ioctl(STDIN_FILENO, TIOCGWINSZ, &w) != 0) {
		perror("ioctl");
		exit(EXIT_FAILURE);
	}

	setup_time_component();
	setup_username_component();
	setup_cwd_component();
	setup_git_branch_component();

	size_t const component_length = compute_length();

	// 5 base lines
	// +1 per component beyond the first
	// +some padding for safety
	if (w.ws_col < 10 + component_length + num_components - 1) {
		put_color(line_color);
		fputs(CORNER_TOP_LEFT LINE_HORIZONTAL T_LEFT, stdout);
		printf(CMP_FMT, CMP_ARG(components[1]));
		put_color(line_color);
		fputs(LINE_VERTICAL, stdout);
		printf(CMP_FMT, CMP_ARG(components[2]));
		fputs("\n", stdout);
		put_color(line_color);
		fputs(CORNER_BOTTOM_LEFT T_LEFT, stdout);
		put_color(ANSI_MAGENTA);
		fputs("$ ", stdout);
		put_color(ANSI_NONE);
		exit(EXIT_SUCCESS);
	}

	fputs("   ", stdout);
	put_color(line_color);
	fputs(CORNER_TOP_LEFT, stdout);
	FOR_EACH_COMPONENT(i, c, {
		for (size_t j = 0; j < c->len; ++j)
			fputs(LINE_HORIZONTAL, stdout);
		if (i < num_components - 1)
			fputs(T_DOWN, stdout);
	});

	fputs(CORNER_TOP_RIGHT "\n", stdout);

	{
		size_t len = 0;
		put_color(line_color);
		fputs(CORNER_TOP_LEFT LINE_HORIZONTAL LINE_HORIZONTAL T_LEFT, stdout);
		FOR_EACH_COMPONENT(i, c, {
			len += c->len + 1;
			printf(CMP_FMT, CMP_ARG(*c));
			if (i < num_components - 1) {
				put_color(line_color);
				fputs(LINE_VERTICAL, stdout);
			}
		});
		put_color(line_color);
		fputs(T_RIGHT, stdout);

		assert(w.ws_col >= component_length + 10);
		size_t lines = w.ws_col - component_length - 10;
		for (size_t i = 0; i < lines; ++i)
			fputs(LINE_HORIZONTAL, stdout);

		fputs(T_LEFT "\n", stdout);
	}


	put_color(line_color);
	fputs(LINE_VERTICAL "  " CORNER_BOTTOM_LEFT, stdout);
	FOR_EACH_COMPONENT(i, c, {
		for (size_t j = 0; j < c->len; ++j)
			fputs(LINE_HORIZONTAL, stdout);
		if (i < num_components - 1)
			fputs(T_UP, stdout);
	});
	fputs(CORNER_BOTTOM_RIGHT "\n", stdout);
	put_color(line_color);
	printf(CORNER_BOTTOM_LEFT T_LEFT);
	put_color(ANSI_MAGENTA);
	fputs("$ ", stdout);
	put_color(ANSI_NONE);

	fflush(stdout);
	return 0;
}

static void setup_time_component(void) {
	Component *time_component = next_component();
	time_t now = time(0);
	struct tm *timeinfo = localtime(&now);

	int hour = timeinfo->tm_hour % 12;
	if (hour == 0) hour = 12;

	sprintf_component(
		time_component,
		"%02d:%02d:%02d %s",
		hour,
		timeinfo->tm_min,
		timeinfo->tm_sec,
		timeinfo->tm_hour < 12 ? "AM" : "PM");
	time_component->color = ANSI_GRAY;
}

static void setup_username_component(void) {
	Component *username_component = next_component();
	char hostname_buf[MAX_COMPONENT_LENGTH] = {0};
	if (gethostname(hostname_buf, MAX_COMPONENT_LENGTH) == -1) {
		perror("gethostname");
		exit(EXIT_FAILURE);
	}
	const char *shell = getenv("SHELL");
	if (!shell) {
		perror("getenv");
		exit(EXIT_FAILURE);
	}

	if (strncmp(shell, "/nix/", 5) == 0) {
		line_color = ANSI_GREEN;
		username_component->color = ANSI_GREEN;
		strcpy_component(username_component, "nix-shell");
	} else {
		username_component->color = ANSI_RED;
		sprintf_component(username_component, "%s@%s", username, hostname_buf);
	}
}

static void setup_cwd_component(void) {
	static const size_t minlen = 7;
	const size_t maxlen = w.ws_col / 2;

	Component *dir_component = next_component();
	char cwd[MAX_COMPONENT_LENGTH] = {0};
	if (!getcwd(cwd, MAX_COMPONENT_LENGTH)) {
		perror("getcwd");
		exit(EXIT_FAILURE);
	}
	dir_component->color = ANSI_BLUE;

	char *trunc = cwd;
	size_t len = strlen(username);
	if (strncmp(trunc, "/home/", 6) == 0 && strncmp(trunc+6, username, len) == 0) {
		trunc += 6 + len - 1;
		*trunc = '~';
	}

	size_t trunc_len = strlen(trunc);
	if (trunc_len > maxlen) {
		bool found_first = false;
		char *last_dirs = NULL;
		size_t last_dirs_len = 0;
		for (size_t i = trunc_len - 1; i > 0; --i) {
			if (trunc[i] == '/') {
				if (found_first) {
					last_dirs = trunc + i + 1;
					last_dirs_len = trunc_len - i;
					break;
				} else {
					found_first = true;
				}
			}
		}
		size_t j = trunc[0] == '~' ? 2 : 1;
		trunc[j++] = '*';
		trunc[j++] = '/';
		memmove(trunc + j, last_dirs, last_dirs_len);
		trunc[last_dirs_len + j] = 0;
	}

	strcpy_component(dir_component, trunc);

	while (dir_component->len < minlen) {
		dir_component->data[dir_component->len++] = ' ';
	}
}

static FILE *popen_or_exit(char const *command, char const *type) {
	FILE *pipe = popen(command, type);
	if (!pipe) {
		perror("popen");
		exit(EXIT_FAILURE);
	}
	return pipe;
}

static void setup_git_branch_component(void) {
	static char branch[MAX_COMPONENT_LENGTH] = {0};
	FILE *pipe = popen_or_exit("git branch --show-current 2>/dev/null", "r");

	size_t i = 0;
	char c;
	while ((c = getc(pipe)) != EOF) {
		if (c == '\n')
			break;
		branch[i++] = c;
	}

	if (pclose(pipe) != 0)
		return;

	if (i == 0) {
		// git branch --show-current shows nothing with a detached head
		pipe = popen_or_exit("git rev-parse --short HEAD", "r");
		while ((c = getc(pipe)) != EOF) {
			if (c == '\n')
				break;
			branch[i++] = c;
		}
		if (pclose(pipe) != 0)
			return;
	}

	Component *git_component = next_component();
	sprintf_component(git_component, "* %s", branch);
	git_component->color = ANSI_GREEN;
}
