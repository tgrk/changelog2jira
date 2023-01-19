#
# Extracts JIRA IDs from CHANGELOG (using Conventional Commits) and call JIRA Webhook Automation
#
# CLI arguments:
#  - `version` - version you want to extract JIRA IDs from
#  - `path` - location of your project that includes CHANGELOG.md
#
# Usage:
#  export JIRA_WEBHOOK_URL=https://automation.atlassian.com/pro/hooks/secret
#  elixir changelog2jira.exs --version=0.1.0 --path=../your/project
#
Mix.install([
  {:earmark_parser, "~> 1.4"},
  {:httpoison, "~> 1.8"}
])

# configuration
jira_webhook_url = System.fetch_env!("JIRA_WEBHOOK_URL")

# get CLI args
case OptionParser.parse(System.argv(), strict: [version: :string, path: :string]) do
  {[path: path, version: version], [], []} ->
    case File.read(Path.join(path, "CHANGELOG.md")) do
      {:ok, markdown} ->
        {:ok, markdown_ast, []} = EarmarkParser.as_ast(markdown)

        # find version changes and parse JIRA IDs from it
        jira_ids =
          markdown_ast
          |> Enum.reduce_while({false, []}, fn
            {"h" <> _, [], [{"a", [{"href", _compare_url}], [^version], %{}}, _date], %{}},
            {false, acc} ->
              {:cont, {true, acc}}

            {"h" <> _, [], [{"a", [{"href", _compare_url}], [_other_version], %{}}, _date], %{}},
            {true, acc} ->
              {:halt, {false, acc}}

            other, {true, acc} ->
              {:cont, {true, [other | acc]}}

            _other, {false, acc} ->
              {:cont, {false, acc}}
          end)
          |> elem(1)
          |> Enum.reverse()
          |> Enum.reduce([], fn
            {"ul", [], children, %{}}, acc ->
              Enum.reduce(children, acc, fn
                {"li", [], [{"strong", [], [jira_id], %{}} | _rest], %{}}, acc ->
                  [jira_id |> String.replace(":", "") |> String.upcase() | acc]

                _other, acc ->
                  acc
              end)

            _other, acc ->
              acc
          end)

        if jira_ids != [] do
          case HTTPoison.post(jira_webhook_url, "{\"issues\": #{inspect(jira_ids)}}", [
                 {"Content-Type", "application/json"}
               ]) do
            {:ok, %{status_code: 200}} ->
              IO.puts("Issues #{inspect(jira_ids)} marked as released")
              System.stop(0)

            {:ok, %{status_code: status_code}} ->
              IO.puts(
                "Unexpected response code #{status_code} while marking issues #{inspect(jira_ids)}"
              )

              System.stop(1)

            {:error, reason} ->
              IO.puts("Error #{inspect(reason)} while marking issues #{inspect(jira_ids)}")
              System.stop(1)
          end
        else
          IO.puts("No JIRA issues for version #{version} found.")
          System.stop(0)
        end

      {:error, reason} ->
        IO.puts(
          "Unable to read the version #{version} from the CHANGELOG file #{path} due to error #{inspect(reason)}"
        )

        System.stop(1)
    end

  _other ->
    IO.puts(
      "Usage: elixir changelog2jira.ex --path=<your_project_changelog> --version=latest"
    )

    System.stop(1)
end
