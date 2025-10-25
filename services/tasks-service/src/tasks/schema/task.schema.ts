import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { HydratedDocument, Document } from 'mongoose';

export type TaskDocument = HydratedDocument<Task>;

@Schema()
export class Task extends Document {
  @Prop({ required: true, trim: true })
  title: string;

  @Prop({ default: false })
  is_done: boolean;

  @Prop({ index: true })
  user_id: string;

  @Prop({ default: Date.now })
  time_created: Date;
}

export const TaskSchema = SchemaFactory.createForClass(Task);
