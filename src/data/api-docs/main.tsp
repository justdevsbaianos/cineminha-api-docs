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

model Entity {
  @visibility("read", "update", "delete")
  id: string;

  @visibility("read")
  createdAt: unixTimestamp32;

  @visibility("read")
  updatedAt: unixTimestamp32;

  @visibility("read")
  deletedAt: unixTimestamp32 | null;
}

namespace Medias {
  model Image {
    ...Entity;
    url: string;
  }
}

@tag("Reports")
@route("/reports")
namespace Reports {
  model ReportRequest {
    target: Users.User.id;
    reason: string;
  }

  model Report {
    ...Entity;

    @doc("Denunciante")
    whistleblower: Users.User;

    @doc("Denunciado")
    target: Users.User;

    @doc("Razão da denúncia")
    reason: string;

    @doc("Quando foi revisado por um admnistrador")
    reviewedAt: unixTimestamp32 | null;

    @doc("Nível de severidade. Indo de algo suave a algum crime.")
    severity: 1 | 2 | 3 | 4 | 5;
  }

  @doc("Cria denúncia com o usuário logado como denunciante")
  @post
  op create(@body request: ReportRequest): SimpleResponse<Report>;

  @doc("Lista as denúncias feitas pelo usuário logado")
  @get
  op list(): PaginatedResponse<Report>;
}

@tag("Statistics")
@route("/statistics")
namespace Statistics {
  @doc("Aplicação cliente responsável pela requisição")
  enum AplicationType {
    WEB,
    MOBILE,
    DESKTOP,
  }
}

@tag("Movies")
@route("/movies")
@useAuth(BearerAuth)
namespace Movies {
  model Movie {
    ...Entity;
    title: string;
    favoriteCount: int32;
    matchesCount: int32;
    voteAverage: int32;
    forAdults: boolean;
    releaseDate: string;
    director: string;
    genres: Genres.Genre[];
    originalLanguage: string;
    overview: string;
    favoritedAt: unixTimestamp32;
    pictures: {
      poster: Medias.Image;
      backgdrop: Medias.Image;
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
    ...Entity;
    movieId: Movies.Movie.id;
    actor: Users.UserProfile;
    participants: Users.UserProfile[];
  }

  @get
  op list(): PaginatedResponse<Match>;

  @post
  op create(@body request: MatchRequest): SimpleResponse<Match>;

  @post
  @route("/many")
  op createMany(
    @body request: {
      ...MatchRequest;
      quantity: int32;
    },
  ): SimpleResponse<Match[]>;

  @patch
  @route("/approve")
  op approve(@path id: string): SimpleResponse<Match>;

  @patch
  @route("/reject")
  op reject(@path id: string): SimpleResponse<Match>;
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

  model Feedback {
    ...Entity;
    userId: Users.User.id;
    message: string;
    type: FeedbackType;
    appType: Statistics.AplicationType;
    appVersion: string;
  }

  @post
  op create(@body feedback: Feedback): SimpleResponse<string>;
}

@tag("Genres")
@route("/genres")
@useAuth(BearerAuth)
namespace Genres {
  model Genre {
    ...Entity;
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
    ...Entity;
    movieId: Movies.Movie.id;
    userId: Users.User.id;
    rating: int32;
    comment: string | null;
  }

  @get
  op list(@query("movieId") movieId: Movies.Movie.id): SimpleResponse<Rating[]>;

  @get
  @route("/user")
  op listUserReviews(@path userId: Users.User.id): PaginatedResponse<Rating>;

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
  @doc("Lista os filmes favoritos do usuário logado.")
  @get
  op list(): PaginatedResponse<Movies.Movie>;

  @doc("Adiciona um filme na lista de favoritos.")
  @post
  op add(@path id: Movies.Movie.id): SimpleResponse<string>;

  @doc("Remove um filme da lista de favoritos.")
  @delete
  op remove(@path id: Movies.Movie.id): SimpleResponse<string>;
}

@tag("Auth")
@route("/auth")
namespace Auth {
  model UserLogin {
    email: string;
    password: string;
  }

  model UserRegistration {
    ...UserLogin;
    ...Users.UserProfile;
  }

  @doc("Registra um novo usuário.")
  @post
  @route("/register")
  op register(@body user: UserRegistration): SimpleResponse<string>;

  @doc("Loga o usuário e retorna um token de autenticação.")
  @post
  @route("/login")
  op login(@body user: UserLogin): SimpleResponse<string>;

  @doc("Desloga o usuário logado. Invalidando o token.")
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

  @doc("Atualiza a senha do usuário logado.")
  @patch
  op update(@bodyRoot data: ChangeRequest): SimpleResponse<string>;

  @doc("Solicita a troca de senha.")
  @post
  @route("/request")
  op requestReset(@bodyRoot data: ResetRequest): SimpleResponse<string>;

  @doc("Confirma a troca de senha.")
  @post
  @route("/reset")
  op confirmReset(@bodyRoot data: ResetData): SimpleResponse<string>;
}

@tag("Users")
@route("/users")
@useAuth(BearerAuth)
namespace Users {
  model UserProfile {
    ...Entity;

    @doc("Nome do usuário")
    name: string;

    @doc("Biografia do usuário")
    bio: string;

    @doc("URL da imagem de perfil")
    avatar: string;

    @doc("Linguagem preferida pelo usuário")
    preferedLanguage: "pt-BR" | "en-US";

    @doc("Gêneros preferidos pelo usuário")
    @visibility("read")
    preferedGenres: Genres[];
  }

  model User extends UserProfile {
    @doc("Email do usuário")
    @visibility("read")
    email: string;
  }

  @doc("Lista os usuários com base em um filtro.")
  @get
  op list(@query("name") name: string): PaginatedResponse<UserProfile>;

  @doc("Busca um usuário pelo ID.")
  @get
  op get(@path id: string): SimpleResponse<UserProfile>;
}

@tag("Me")
@route("/users/me")
@useAuth(BearerAuth)
namespace Me {
  @doc("Busca o perfil o usuário logado com dados a mais.")
  @get
  op get(): SimpleResponse<Users.User>;

  @doc("Atualiza o perfil do usuário logado.")
  @put
  op update(@body profile: Users.UserProfile): SimpleResponse<string>;
}

@tag("Friends")
@route("/friends")
@useAuth(BearerAuth)
namespace Friends {
  model Friend {
    ...Users.UserProfile;

    @doc("Contador de términos entre o usuário consultado e o usuário listado.")
    breackupCount: integer;
  }

  model FriendRequest {
    userId: Users.User.id;

    @doc("Um número entre 0 e 1 representando o quando o usuário logado gosta desse usuário. Isso pode ou não afetar o resultado de uma combinação.")
    loveLevel: float;
  }

  @doc("Lista os amigos de um usuário.")
  @get
  @route("/of")
  op friendOf(@path userId: Users.User.id): PaginatedResponse<Friend>;

  @doc("Adiciona um novo amigo.")
  @post
  op add(@body body: FriendRequest): SimpleResponse<string>;

  @doc("Atualiza um amigo.")
  @put
  op update(@body body: FriendRequest): SimpleResponse<string>;

  @doc("Remove um amigo. Isso afeta o contador de términos com esse usuário para o usuário logado.")
  @delete
  op remove(@path friendId: Friend.id): SimpleResponse<string>;
}
