export interface Author {
  id: number;
  firstName: string;
  lastName: string;
  age: number | null;
  genres: string[];
}

export interface Book {
  id: number;
  title: string;
  argument: string;
  genre: string;
  authorIds: number[];
  publisherId: number | null;
}

export interface Publisher {
  id: number;
  name: string;
  country: string;
}

export interface ErrorResponse {
  message: string;
}
