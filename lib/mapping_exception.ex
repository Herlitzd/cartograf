defmodule Cartograf.MappingException do
  @message "Field not mapped."
  defexception message: @message, field: nil
end
