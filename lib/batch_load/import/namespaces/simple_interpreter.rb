module BatchLoad
  class Import::Namespaces::SimpleInterpreter < BatchLoad::Import

    def initialize(**args)
      super(args)
    end

    def build_namespaces
      @total_data_lines = 0
      i = 1

      namespaces = {};

      # loop throw rows
      csv.each do |row|

        parse_result = BatchLoad::RowParse.new
        parse_result.objects[:namespaces] = []

        @processed_rows[i] = parse_result

        begin
          namespace_attributes = {
            institution: row["institution"],
            name: row["name"],
            short_name: row["short_name"],
            verbatim_short_name: row["verbatim_short_name"]
          };

          namespace = Namespace.new(namespace_attributes)
          parse_result.objects[:namespaces].push namespace
          @total_data_lines += 1 if namespace.present?
        # rescue TODO: THIS IS A GENERATED STUB, it does not function
        end
        i += 1
      end

      @total_lines = i - 1
    end

    def build
      if valid?
        build_namespaces
        @processed = true
      end
    end

  end
end
