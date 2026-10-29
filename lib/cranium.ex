defmodule Cranium do
  # works for development but needs to be changed for production
  @base_url "http://127.0.0.1:3000/api/"
  @fun_facts ["The Swedish parliament is called riksdag and it has 349 members in a single chamber.",
  "Sweden is so long that it's possible for northern parts to have snow on the ground despite the south being in bloom.",
  "In Norway, the lake Hornindalsvatnet is the deepest lake in Europe.",
  "Located in Norway, Sognefjorden is the world's second deepest fjord.",
  "Denmark is one of the happiest countries in the world according to the UN world happiness report.",
  "The Danish flag “Dannebrog” is the world's oldest flag, being first acknowledged in 1219.",
  "Around 75% of Finland's surface area is covered with forests, and Finland is home to the world's largest archipelago.",
  "In Helsinki, 11 out of 12 lost wallets are returned to their owners."]

  # /Users/reeceturner/.local/libs
  @packages_directory "~/.local/libs" |> Path.expand

  defp query endpoint do
    uri = @base_url <> endpoint
    case Req.get(uri) do
      {:ok, response} -> response.body
      {:error, _reason} -> IO.puts "Something went wrong while contacting the server."; System.halt
    end
  end

  # ensures a package name is valid
  defp validate_package_name(package) do
    cond do
      # package name contains numbers
      String.match?(package, ~r/\d/) ->
        IO.puts "Invalid package name: #{package}. Package names cannot contain numbers."

        # package name contains special characters
      String.match?(package, ~r/[^\p{L}\s]/) ->
        IO.puts "Invalid package name: #{package}. Package names cannot contain  special characters"

      # package name is valid
      true ->
        :ok
    end
  end

  # no package was provided
  def fetch([]) do
    IO.puts "You didn't share a package — what package would you like to install?"
    System.halt
  end

  # install a package
  def fetch package do
    validate_package_name(package)

    body = query("install/#{package}")

    package_name = body["name"]

    IO.puts "Cranium would install #{package_name}"
  end


  # displays the top five packages for today (24 hours)
  def serve_omakase do
    %{
      "name" => name,
      "description" => description,
      "github_url" => github_url
      } = query("omakase")

    # change the wording of this
    IO.puts("Omakase package: #{name}, #{description}, #{github_url}")
  end

  # displays a random package
  def pick_random_package do
    %{
      "name" => name,
      "description" => description,
      "github_url" => github_url
      } = query("packages/random")

      # change the wording of this
      IO.puts("Random package: #{name}, #{description}, #{github_url}")
  end

  # verify the timeframe used in the wipe command.
  # It must follow this syntax:
  defp verify_timeframe(timeframe) do
    case String.match?(timeframe, ~r/(older|younger) than (\d) days/) do
      false ->
        IO.puts "Invalid timeframe given: #{timeframe}. It must follow this syntax: older/younger than x days"
        System.halt
      _ -> true
    end
  end

  # delete all packages
  def delete_packages([]) do
    IO.puts "Would delete all packages"
  end

  # delete all packages within a timeframe
  def delete_packages(args) do
    timeframe = Enum.join(args, " ")

    verify_timeframe(timeframe)

    IO.puts "Would delete all packages within a timeframe: #{timeframe}"
  end

  # displays a random fun fact
  def provide_fun_fact do
    Enum.random(@fun_facts)
    |> IO.puts
  end

  # no project was provided
  def clone_into([]) do
    IO.puts "You didn't share a package — what package would you like to clone into?"
    System.halt
  end

  # git clone a package (doesn't install)
  def clone_into([project | _rest]) do
    %{"github_url" => github_url} = query("packages/clone/#{project}")

    IO.puts "Would clone into #{github_url}"
  end

  # displays all packages you have installed
  def your_packages do
    files = case File.ls(@packages_directory) do
      {:ok, files} -> files
      {:error, _reason} -> IO.puts "Failed to read the libs/ directory."
    end

    if length(files) == 0 do
      IO.puts "You have no packages installed."
    else
      IO.puts "All packages:"
      Enum.each(files, fn file ->
        IO.puts "#{file}"
      end)
    end
  end

  def print_upload_message do
    "You cannot upload libraries through the Cranium CLI. To upload a library, please visit the Cranium website."
    |> IO.puts
  end



  def main([command | rest]) do
    if !File.dir?(@packages_directory) do
      IO.puts "Something went wrong: you are missing the packages directory: ~/.local/libs/"
      IO.puts "Try running `mkdir ~/.local/libs`."
      System.halt
    end

    case command do
      "fetch" -> fetch(rest)
      "omakase" -> serve_omakase()
      "random" -> pick_random_package()
      "delete" -> delete_packages(rest)
      "fun-fact" -> provide_fun_fact()
      "tear-apart" -> clone_into(rest)
      "list" -> your_packages()
      "upload" -> print_upload_message()
      _ ->
        IO.puts "That's not a recognized command. Type 'help' for a list of the commands."
    end
  end

  # no command was passed
  def main([]) do
    "Please provide a command. Type 'help' for a list of commands."
    |> IO.puts
  end
end
