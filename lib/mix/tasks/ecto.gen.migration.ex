defmodule Mix.Tasks.Ecto.Gen.Migration do
  use Mix.Task
  import Mix.Ecto
  import Mix.Generator
  import Mix.Utils, only: [camelize: 1]

  @shortdoc "Generate a new migration for the repo"

  @moduledoc """
  Generates a migration.

  ## Examples

      mix ecto.gen.migration add_posts_table
      mix ecto.gen.migration add_posts_table -r Custom.Repo

  By default, the migration will be generated to the
  "priv/YOUR_REPO/migrations" directory of the current application
  but it can be configured by specify the `:priv` key under
  the repository configuration.

  ## Command line options

    * `-r`, `--repo` - the repo to generate migration for (defaults to `YourApp.Repo`)
    * `--no-start` - do not start applications

  """

  @doc false
  def run(args) do
    no_umbrella!("ecto.gen.migration")

    Mix.Task.run "app.start", args
    repo = parse_repo(args)

    case OptionParser.parse(args) do
      {_, [name], _} ->
        ensure_repo(repo)
        path = Path.relative_to(migrations_path(repo), Mix.Project.app_path)
        file = Path.join(path, "#{timestamp}_#{name}.exs")
        create_directory path
        create_file file, migration_template(mod: Module.concat([repo, Migrations, camelize(name)]))

        if open?(file) && Mix.shell.yes?("Do you want to run this migration?") do
          Mix.Task.run "ecto.migrate", [repo]
        end
      {_, _, _} ->
        Mix.raise "expected ecto.gen.migration to receive the migration file name, " <>
                  "got: #{inspect Enum.join(args, " ")}"
    end
  end

  defp timestamp do
    {{y, m, d}, {hh, mm, ss}} = :calendar.universal_time()
    "#{y}#{pad(m)}#{pad(d)}#{pad(hh)}#{pad(mm)}#{pad(ss)}"
  end

  defp pad(i) when i < 10, do: << ?0, ?0 + i >>
  defp pad(i), do: to_string(i)

  embed_template :migration, """
  defmodule <%= inspect @mod %> do
    use Ecto.Migration

    def up do
    end

    def down do
    end
  end
  """
end
