module Kran
  # Shellwords escapes "=" and ":" and uses backslashes, which makes every
  # printed kubectl and docker command harder to read than necessary. Safe
  # words stay bare; anything else is wrapped in single quotes.
  module Shell
    SAFE_WORD = %r{\A[\w@%+=:,./-]+\z}

    extend self

    def escape(word)
      word = word.to_s
      word.match?(SAFE_WORD) ? word : "'#{word.gsub("'", "'\\\\''")}'"
    end

    def join(words)
      words.map { |word| escape(word) }.join(" ")
    end

    def with_env(env, command)
      assignments = env.map { |name, value| "#{name}=#{escape(value)}" }
      [*assignments, command].join(" ")
    end
  end
end
