export interface Author {
  id: number;
  firstName: string;
  lastName: string;
  age: number | null;
}

export interface Book {
  id: number;
  title: string;
  description: string;
  authorIds: number[];
}

export interface ErrorResponse {
  message: string;
}
