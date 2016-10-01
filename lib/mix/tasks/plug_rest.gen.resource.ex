defmodule Mix.Tasks.PlugRest.Gen.Resource do
  use Mix.Task

  import Mix.Generator

  @shortdoc "Generates a PlugRest resource"

  @moduledoc """
  Generates a PlugRest resource in your Plug application.

      mix plug_rest.gen.resource UserResource

  The generated resource will contain:

    * a resource file in lib/my_app/resources

  The resources target directory can be changed with the option:

      mix plug_rest.gen.resource UserResource --dir "web/resources"

  In an umbrella project, run the mix task in the root of the app, or
  specify the app with:

      mix plug_rest.gen.resource UserResource --app my_app
  """
  def run(args) do
    switches = [dir: :binary, use: :binary, app: :string]
    {opts, parsed, _} = OptionParser.parse(args, switches: switches)

    resource =
      case parsed do
        [] -> Mix.raise "plug_rest.gen.resource expects a Resource name to be given"
        [resource] -> resource
        [_ | _] -> Mix.raise "plug_rest.gen.resource expects a single Resource name"
      end

    app_lib = case Mix.Project.umbrella? or !is_nil(opts[:app]) do
                true ->
                  opts[:app]
                false  ->
                  Mix.Project.config |> Keyword.get(:app) |> Atom.to_string
              end

    if is_nil(app_lib) do
      Mix.raise ("The app must be specified in mix.exs or with the --app switch")
    end

    apps_path = case Mix.Project.umbrella? do
                  true -> Path.join([Mix.Project.config[:apps_path], app_lib])
                  false -> "."
                end

    underscored = Macro.underscore(resource)
    app_mod = Macro.camelize(app_lib)

    default_opts = [dir: Path.join([apps_path, "lib", app_lib, "resources"]),
                    use: "PlugRest.Resource"]

    opts = Keyword.merge(default_opts, opts)

    resource_module = Enum.join([app_mod, resource], ".")

    file = Path.join([opts[:dir], underscored]) <> ".ex"
    create_directory Path.dirname(file)

    plug_app_dir = Application.app_dir(:plug_rest)
    template_path = "priv/templates/plug_rest.gen.resource/resource.ex"
    template = Path.join(plug_app_dir, template_path)
    contents = EEx.eval_file(template, [module: resource_module,
                                        resources_use: opts[:use]])

    :ok = File.write(file, contents)

    Mix.shell.info """
    #{resource_module} created at #{file}
    """
  end
end
