defmodule ExmqttcRegexTest do
  use ExUnit.Case, async: false

  test "parsing a simple topic to regex" do
    topic = "test/123"
    {:ok, regex} = Exmqttc.TopicParser.compile(topic)
    assert Regex.match?(regex, topic)
  end

  test "parsing a + placeholder topic to regex" do
    topic = "test/+"
    {:ok, regex} = Exmqttc.TopicParser.compile(topic)
    assert Regex.match?(regex, "test/123")
    refute Regex.match?(regex, "test/123/321")
  end

  test "parsing a # placeholder topic to regex" do
    topic = "test/#"
    {:ok, regex} = Exmqttc.TopicParser.compile(topic)
    assert Regex.match?(regex, "test/123")
    assert Regex.match?(regex, "test/123/321")
  end
end

defmodule Exmqttc.TopicParser do
  def tokenize(topic) do
    String.split(topic, "/")
  end

  def compile(topic) do
    regex =
      topic
      |> tokenize
      |> Enum.map(&replace/1)
      |> Enum.join("/")

    Regex.compile("^#{regex}$")
  end

  def replace("+" <> _data) do
    "[a-zA-Z0-9_-]+"
  end

  def replace("#") do
    ".*"
  end

  def replace(input) do
    input
  end
end
