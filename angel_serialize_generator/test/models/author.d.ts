// GENERATED CODE - DO NOT MODIFY BY HAND
interface Library {
  id?: string;
  collection?: LibraryCollection;
  created_at?: any;
  updated_at?: any;
}
interface LibraryCollection {
  [key: string]: Book;
}
interface Bookmark {
  id?: string;
  history?: number[];
  page: number;
  comment?: string;
  created_at?: any;
  updated_at?: any;
}
