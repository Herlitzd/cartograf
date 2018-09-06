defmodule Cartograf.MappingException do
  @moduledoc """
  Exception to be reported when fields aren't mapped.
  """
  @message "Field not mapped."
  defexception message: @message
end
