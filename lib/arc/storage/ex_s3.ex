defmodule Arc.Storage.ExS3 do
  @default_expire_time 60*5
  @valid_schemes ~w{http:// https://}
  @metadata_prefix "x-amz-meta-"

  alias Arc.Storage.S3

  alias ExAws.Auth.Credentials
  alias ExAws.Auth.Utils
  alias ExAws.Auth.Signatures

  defdelegate put(definition, version, file_and_scope), to: S3
  defdelegate delete(definition, version, file_and_scope), to: S3

  def url(definition, version, file_and_scope, options \\ []) do
    if Keyword.get(options, :signed) do
      S3.url(definition, version, file_and_scope, options)
    else
      scheme = extract_scheme()
      host = Keyword.get(Application.fetch_env!(:ex_aws, :s3), :host)
      port = Keyword.get(Application.fetch_env!(:ex_aws, :s3), :port)
      port =
        if is_integer(port) do
          port
        else
          String.to_integer(port)
        end

      bucket = definition.storage_bucket()
      key = definition.storage_key(version, file_and_scope)

      %URI{
        scheme: scheme,
        host: host,
        port: port,
        path: Path.join(["/", bucket, key])
      }
      |> URI.to_string()
    end
  end

  def presigned_put_url(definition, file_and_scope) do
    s3_bucket = definition.storage_bucket()
    s3_key = definition.storage_key(nil, file_and_scope)

    {:ok, url} = ExAws.S3.presigned_url(config(), :put, s3_bucket, s3_key, expires_in: @default_expire_time)
    url
  end

  def head(%{bucket: bucket, key: key}) do
    result =
      bucket
      |> ExAws.S3.head_object(key)
      |> ExAws.request()

    case result do
      {:ok, _} -> true
      _ -> false
    end
  end

  #
  # Post Object
  #

  def post_object_policy_conditions(_definition, policy, options) do
    case Keyword.get(options, :metadata) do
      nil -> policy
      metadata when is_list(metadata) or is_map(metadata) ->
        policy ++ [metadata(metadata)]
    end
  end

  def post_object_auth_data(%{} = raw_data, policy, options) do
    config = config()
    datetime = :calendar.universal_time

    auth_header = %{
      "x-amz-algorithm": "AWS4-HMAC-SHA256",
      "x-amz-credential": Credentials.generate_credential_v4(:s3, config, datetime),
      "x-amz-date": Utils.amz_date(datetime),
      "x-amz-signature": Signatures.generate_signature_v4("s3", config, datetime, policy)
    }
    |> Map.merge(raw_data)

    case Keyword.get(options, :metadata) do
      nil -> auth_header
      metadata when is_list(metadata) or is_map(metadata) ->
        Map.merge(auth_header, metadata(metadata))
    end
  end

  def post_object_url(%{bucket: bucket}) do
    config = config()

    scheme = extract_scheme(config)
    port = case config.port do
      binport when is_binary(binport) -> String.to_integer(binport)
      port -> port
    end

    %URI{
      scheme: scheme,
      host: config.host,
      port: port,
      path: Path.join("/", bucket)
    }
    |> URI.to_string()
  end

  defp metadata(metadata) do
    metadata
    |> Enum.map(fn {field, value} ->
      {@metadata_prefix <> to_string(field), value}
    end)
    |> Map.new()
  end

  defp extract_scheme do
    extract_scheme(config())
  end
  defp extract_scheme(%{scheme: scheme}) when scheme in @valid_schemes do
    String.replace_suffix(scheme, "://", "")
  end
  defp extract_scheme(_) do
    "http"
  end

  #
  # Helpers
  #

  defp config do
    ExAws.Config.new(:s3, Application.get_all_env(:ex_aws))
  end
end
