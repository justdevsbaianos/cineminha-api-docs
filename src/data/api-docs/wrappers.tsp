import "@typespec/http";

using TypeSpec.Http;

namespace Wrappers {
  model Error {
    message: string;
  }

  @error
  model ErrorResponse {
    error: Error;
  }

  model SuccesfulPaginatedResponse<T> {
    result: T[];
    metadata: {
      total: int32;
    };
  }

  model SuccesfulResponse<T> {
    result: T;
  }

  alias PaginatedResponse<T> = SuccesfulPaginatedResponse<T> | ErrorResponse;

  alias SimpleResponse<T> = SuccesfulResponse<T> | ErrorResponse;
}
