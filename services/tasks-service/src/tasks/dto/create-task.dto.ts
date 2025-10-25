import { Types } from 'mongoose';

export class CreateTaskDto {
  title: string;
  user_id: Types.ObjectId;
}
