import "@typespec/http";
import "@typespec/rest";
import "@typespec/openapi3";
import "./wrappers.tsp";

using TypeSpec.Http;
using TypeSpec.Rest;
using Wrappers;

@service({
  title: "Cineminha API",
})
@server("http://localhost:8080", "development")
@server("https://api.cineminha.online", "production")
namespace Cineminha;

model WithId {
  @visibility("read", "update", "delete")
  id: string;
}

@tag("Movies")
@route("/movies")
@useAuth(BearerAuth)
namespace Movies {
  model Image {
    ...WithId;
    url: string;
  }

  model Movie {
    ...WithId;
    title: string;
    description: string;
    favoriteCount: string;
    parentalRating: string;
    year: int32;
    director: string;
    pictures: {
      poster: Image;
    };
  }

  model DetailedMovie extends Movie {
    plot: string;
  }

  @get
  op list(
    @query("year") year?: int32,
    @query("director") director?: string,
    @query("search") search?: string,
    @query("limit") limit?: int32,
    @query("skip") skip?: int32,
  ): PaginatedResponse<Movie>;

  @get
  op getById(@path id: string): SimpleResponse<DetailedMovie>;
}

@tag("Matches")
@route("/matches")
@useAuth(BearerAuth)
namespace Matches {
  model MatchRequest {
    participants: string[];
  }

  model Match {
    ...WithId;
    movieId: string;
    matchedAt: string;
    actor: Users.UserProfile;
    participants: Users.UserProfile[];
  }

  @get
  op list(): PaginatedResponse<Match>;

  @post
  op create(@body request: MatchRequest): SimpleResponse<Match>;

  @put
  op update(
    @path id: string,
    @body request: MatchRequest,
  ): SimpleResponse<Match>;
}

@tag("System feedback")
@route("/feedback")
@useAuth(BearerAuth)
namespace Feedback {
  enum FeedbackType {
    BUG,
    FEATURE,
    IMPROVEMENT,
    OTHER,
  }

  enum ApllicationType {
    WEB,
    MOBILE,
    DESKTOP,
  }

  model Feedback {
    ...WithId;
    userId: string;
    message: string;
    createdAt: string;
    type: FeedbackType;
    application: ApllicationType;
  }

  @post
  op create(@body feedback: Feedback): SimpleResponse<string>;
}

@tag("Genres")
@route("/genres")
@useAuth(BearerAuth)
namespace Genres {
  model Genre {
    ...WithId;
    name: string;
  }

  @get
  op list(): SimpleResponse<Genre[]>;
}

@tag("Ratings")
@route("/ratings")
@useAuth(BearerAuth)
namespace Ratings {
  model Rating {
    ...WithId;
    movieId: string;
    userId: string;
    rating: int32;
    comment: string | null;
  }

  @get
  op list(@query("movieId") movieId: string): SimpleResponse<Rating[]>;

  @post
  op add(@body rating: Rating): SimpleResponse<string>;

  @put
  op update(@body rating: Rating): SimpleResponse<string>;

  @delete
  op remove(@path id: string): SimpleResponse<string>;
}

@tag("Favorites")
@route("/favorites")
@useAuth(BearerAuth)
namespace Favorites {
  @get
  op list(): PaginatedResponse<Movies.Movie>;

  @post
  op add(@path id: string): SimpleResponse<string>;

  @delete
  op remove(@path id: string): SimpleResponse<string>;
}

@tag("Auth")
@route("/auth")
namespace Auth {
  model UserLogin {
    email: string;
    password: string;
  }

  model UserRegistration extends UserLogin {
    name: string;
  }

  @post
  @route("/register")
  op register(@body user: UserRegistration): SimpleResponse<string>;

  @post
  @route("/login")
  op login(@body user: UserLogin): SimpleResponse<string>;

  @post
  @route("/logout")
  @useAuth(BearerAuth)
  op logout(): SimpleResponse<string>;
}

@tag("Password")
@route("/auth/password")
@useAuth(BearerAuth)
namespace Password {
  model ResetRequest {
    email: string;
  }

  model ResetData {
    token: string;
    password: string;
  }

  model ChangeRequest {
    oldPassword: string;
    newPassword: string;
  }

  @patch
  op update(@bodyRoot data: ChangeRequest): SimpleResponse<string>;

  @post
  @route("/request")
  op requestReset(@bodyRoot data: ResetRequest): SimpleResponse<string>;

  @post
  @route("/reset")
  op confirmReset(@bodyRoot data: ResetData): SimpleResponse<string>;
}

@tag("Users")
@route("/users")
@useAuth(BearerAuth)
namespace Users {
  model UserProfile {
    ...WithId;
    name: string;
    bio: string;
    avatar: string;
    preferedLanguage: string;
  }

  model User extends UserProfile {
    email: string;
  }

  @get
  op list(@query("name") name: string): PaginatedResponse<UserProfile>;

  @get
  op get(@path id: string): SimpleResponse<UserProfile>;
}

@tag("Me")
@route("/users/me")
@useAuth(BearerAuth)
namespace Me {
  @get
  op get(): SimpleResponse<Users.User>;

  @put
  op update(@body profile: Users.UserProfile): SimpleResponse<string>;
}

@tag("Friends")
@route("/friends")
@useAuth(BearerAuth)
namespace Friends {
  @get
  op list(): PaginatedResponse<Users.UserProfile>;

  @post
  op add(@path id: string): SimpleResponse<string>;

  @delete
  op remove(@path id: string): SimpleResponse<string>;
}
