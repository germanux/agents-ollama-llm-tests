import { Injectable } from '@angular/core';
import { Title } from '@angular/platform-browser';

@Injectable({
  providedIn: 'root'
})
export class PageTitleService {
  private readonly baseTitle = 'Library Management';

  constructor(private titleService: Title) {}

  setTitle(title: string): void {
    this.titleService.setTitle(`${title} - ${this.baseTitle}`);
  }
}
