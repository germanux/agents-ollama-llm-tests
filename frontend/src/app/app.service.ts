import { Injectable } from '@angular/core';
import { BehaviorSubject, Observable } from 'rxjs';
import { AuthorDto } from '../api.service';

@Injectable({
  providedIn: 'root'
})
export class AppService {
  private selectedAuthorSubject = new BehaviorSubject<AuthorDto | null>(null);
  selectedAuthor$: Observable<AuthorDto | null> = this.selectedAuthorSubject.asObservable();

  setSelectedAuthor(author: AuthorDto | null): void {
    this.selectedAuthorSubject.next(author);
  }

  getSelectedAuthor(): AuthorDto | null {
    return this.selectedAuthorSubject.getValue();
  }
}
