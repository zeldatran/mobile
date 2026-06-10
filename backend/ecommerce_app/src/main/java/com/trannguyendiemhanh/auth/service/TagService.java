package com.trannguyendiemhanh.auth.service;

import java.util.List;
import java.util.UUID;

import com.trannguyendiemhanh.auth.entity.Tag;

public interface TagService {
    Tag createTag(Tag tag);
    Tag getTagById(UUID id);
    Tag getTagByName(String tagName);
    List<Tag> getAllTags();
    void deleteTag(UUID id);
}
