import { Injectable } from '@angular/core';
import { HttpClient, HttpErrorResponse } from '@angular/common/http';
import { Observable, catchError, throwError } from 'rxjs';

export interface Author {
  id?: number;
  firstName: string;
  lastName: string;
  age: number;
}

export interface Book {
  id?: number;
  title: string;
  authors?: string[];
}

export interface BookCreateDto {
  title: string;
  description: string;
  authorIds: number[];
}

@Injectable({
  providedIn: 'root'
})
export class ApiService {
  private readonly baseUrl = '/api';

  constructor(private http: HttpClient) {}

  getAuthors(): Observable<Author[]> {
    return this.http.get<Author[]>(`${this.baseUrl}/authors`)
      .pipe(catchError(this.handleError));
  }

  createAuthor(author: Author): Observable<Author> {
    return this.http.post<Author>(`${this.baseUrl}/authors`, author)
      .pipe(catchError(this.handleError));
  }

  getBooks(): Observable<Book[]> {
    return this.http.get<Book[]>(`${this.baseUrl}/books`)
      .pipe(catchError(this.handleError));
  }

  createBook(book: BookCreateDto): Observable<Book> {
    return this.http.post<Book>(`${this.baseUrl}/books`, book)
      .pipe(catchError(this.handleError));
  }

  getBooksByAuthorId(authorId: number): Observable<Book[]> {
    return this.http.get<Book[]>(`${this.baseUrl}/books/author/${authorId}/titles`)
      .pipe(catchError(this.handleError));
  }

  private handleError(error: HttpErrorResponse) {
    let errorMessage = 'An error occurred';
    
    if (error.error instanceof ProgressEvent) {
      errorMessage = 'Network error - unable to connect to server';
    } else if (error.status === 0) {
      errorMessage = 'Server is not running. Please start the backend.';
    } else {
      errorMessage = `Error: ${error.message}`;
    }
    
    return throwError(() => new Error(errorMessage));
  }
}
