# Sourced by apply.sh. One `inst <binary> '<install command>'` per tool that no package
# manager in the manifest covers. apply.sh skips a line when <binary> is already on PATH.
# A tool with no known installer stays as a `todo` line so verify.sh reports it.

inst mise        'curl -fsSL https://mise.run | sh'
inst uv          'curl -LsSf https://astral.sh/uv/install.sh | sh'
inst claude      'curl -fsSL https://claude.ai/install.sh | bash'
inst cursor-agent 'curl -fsS https://cursor.com/install | bash'
inst herdr       'curl -fsSL https://herdr.dev/install.sh | sh'
inst ollama      'curl -fsSL https://ollama.com/install.sh | sh'
