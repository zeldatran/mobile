package com.trannguyendiemhanh.auth.service.impl;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import com.trannguyendiemhanh.auth.entity.Tag;
import com.trannguyendiemhanh.auth.repository.TagRepository;
import com.trannguyendiemhanh.auth.service.TagService;

import java.util.List;
import java.util.UUID;

@Service
public class TagServiceImpl implements TagService {

    private final TagRepository tagRepository;

    @Autowired
    public TagServiceImpl(TagRepository tagRepository) {
        this.tagRepository = tagRepository;
    }

    @Override
    public Tag createTag(Tag tag) {
        if (tagRepository.findByTagName(tag.getTagName()).isPresent()) {
            throw new RuntimeException("Tag already exists: " + tag.getTagName());
        }
        return tagRepository.save(tag);
    }

    @Override
    public Tag getTagById(UUID id) {
        return tagRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Tag not found with ID: " + id));
    }

    @Override
    public Tag getTagByName(String tagName) {
        return tagRepository.findByTagName(tagName)
                .orElseThrow(() -> new RuntimeException("Tag not found with Name: " + tagName));
    }

    @Override
    public List<Tag> getAllTags() {
        return tagRepository.findAll();
    }

    @Override
    public void deleteTag(UUID id) {
        tagRepository.deleteById(id);
    }
}
