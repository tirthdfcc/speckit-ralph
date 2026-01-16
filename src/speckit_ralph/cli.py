"""Ralph Wiggum Loop CLI."""

import os
import subprocess
import sys
from pathlib import Path
from typing import Optional

import typer
from rich.console import Console

app = typer.Typer(
    name="ralph",
    help="Ralph Wiggum Loop - Iterative AI coding for Claude Code and Codex",
    no_args_is_help=True,
)
console = Console()


def get_scripts_dir() -> Path:
    """Get the path to bundled scripts directory."""
    return Path(__file__).parent / "scripts"


def run_script(script_name: str, args: list[str] | None = None, env: dict | None = None) -> int:
    """Run a bash script from the scripts directory."""
    script_path = get_scripts_dir() / script_name

    if not script_path.exists():
        console.print(f"[red]Error: Script not found: {script_path}[/red]")
        return 1

    cmd = ["bash", str(script_path)]
    if args:
        cmd.extend(args)

    run_env = os.environ.copy()
    if env:
        run_env.update(env)

    result = subprocess.run(cmd, env=run_env)
    return result.returncode


@app.command()
def once(
    cli: str = typer.Option("claude", "--cli", "-c", help="CLI to use: claude or codex"),
    keep_artifacts: bool = typer.Option(False, "--keep-artifacts", "-k", help="Keep temp files for debugging"),
    promise: str = typer.Option("COMPLETE", "--promise", "-p", help="Completion promise string"),
):
    """Run a single Ralph iteration."""
    script = f"ralph-once-{cli}.sh"

    env = {"RALPH_PROMISE": promise}
    if keep_artifacts:
        env["RALPH_ARTIFACT_DIR"] = f"/tmp/ralph-{cli}-debug"

    sys.exit(run_script(script, env=env))


@app.command()
def loop(
    iterations: int = typer.Argument(..., help="Number of iterations to run"),
    cli: str = typer.Option("claude", "--cli", "-c", help="CLI to use: claude or codex"),
    detach: bool = typer.Option(False, "--detach", "-d", help="Run in background"),
    keep_artifacts: bool = typer.Option(False, "--keep-artifacts", "-k", help="Keep temp files"),
    promise: str = typer.Option("COMPLETE", "--promise", "-p", help="Completion promise string"),
    sleep: int = typer.Option(2, "--sleep", "-s", help="Seconds between iterations"),
):
    """Run Ralph loop for multiple iterations."""
    script = f"afk-ralph-{cli}.sh"

    args = [str(iterations)]
    if detach:
        args.append("--detach")

    env = {
        "RALPH_PROMISE": promise,
        "RALPH_SLEEP_SECONDS": str(sleep),
    }
    if keep_artifacts:
        env["RALPH_ARTIFACT_DIR"] = f"/tmp/ralph-{cli}-loop"

    sys.exit(run_script(script, args=args, env=env))


@app.command()
def build_prompt(
    output: Optional[Path] = typer.Option(None, "--output", "-o", help="Output file path"),
):
    """Generate Ralph prompt from template."""
    args = []
    if output:
        args.extend(["--output", str(output)])

    sys.exit(run_script("build-prompt.sh", args=args))


@app.command()
def scripts_path():
    """Print path to bundled scripts directory."""
    console.print(get_scripts_dir())


if __name__ == "__main__":
    app()
