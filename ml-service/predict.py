"""
Handwriting Recognition Cog Model
Converts HuggingFace Space app to Replicate Cog model.
"""

import os
import torch
import open_clip
import base64
import io
import logging
from PIL import Image
from typing import Dict, Tuple, Optional
import numpy as np
import cog
import cv2
import time

# Configure logging (no prints, but for debugging)
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class Predictor(cog.Predictor):
    def setup(self):
        """Load CLIP model and templates once at startup."""
        logger.info("Setting up CLIP model...")
        
        # Load CLIP model
        self.clip_model, _, self.clip_preprocess = open_clip.create_model_and_transforms(
            'ViT-B-32', pretrained='openai'
        )
        self.clip_model.eval()
        
        # Load letter templates
        self.letter_embeddings = self._load_letter_embeddings()
        
        # Load digit templates  
        self.digit_embeddings = self._load_digit_embeddings()
        
        # Load sentence templates
        self.sentence_embeddings = self._load_sentence_embeddings()
        
        # Cache quality embeddings
        self.quality_embeddings = self._cache_quality_embeddings()
        
        logger.info("Setup complete")

    def _load_letter_embeddings(self) -> Dict[str, torch.Tensor]:
        """Load letter template embeddings."""
        embeddings = {}
        letters_dir = os.path.join(os.path.dirname(__file__), "reference_shapes", "letters")
        
        if not os.path.exists(letters_dir):
            logger.warning("Letters directory not found")
            return embeddings
            
        for letter in sorted(os.listdir(letters_dir)):
            letter_path = os.path.join(letters_dir, letter)
            if not os.path.isdir(letter_path):
                continue
                
            char = letter.upper()
            template_files = [f for f in os.listdir(letter_path) if f.endswith('.png')]
            
            if template_files:
                emb_list = []
                for tf in template_files:
                    img_path = os.path.join(letter_path, tf)
                    img = Image.open(img_path).convert('RGB')
                    processed = self.clip_preprocess(img).unsqueeze(0)
                    with torch.no_grad():
                        emb = self.clip_model.encode_image(processed)
                        emb_list.append(emb.squeeze())
                
                embeddings[char] = torch.stack(emb_list).mean(dim=0)
        
        return embeddings

    def _load_digit_embeddings(self) -> Dict[str, torch.Tensor]:
        """Load digit template embeddings."""
        embeddings = {}
        digits_dir = os.path.join(os.path.dirname(__file__), "reference_shapes", "digits")
        
        if not os.path.exists(digits_dir):
            logger.warning("Digits directory not found")
            return embeddings
            
        for digit in sorted(os.listdir(digits_dir)):
            digit_path = os.path.join(digits_dir, digit)
            if not os.path.isdir(digit_path):
                continue
                
            template_files = [f for f in os.listdir(digit_path) if f.endswith('.png')]
            
            if template_files:
                emb_list = []
                for tf in template_files:
                    img_path = os.path.join(digit_path, tf)
                    img = Image.open(img_path).convert('RGB')
                    processed = self.clip_preprocess(img).unsqueeze(0)
                    with torch.no_grad():
                        emb = self.clip_model.encode_image(processed)
                        emb_list.append(emb.squeeze())
                
                embeddings[digit] = torch.stack(emb_list).mean(dim=0)
        
        return embeddings

    def _load_sentence_embeddings(self) -> Dict[str, torch.Tensor]:
        """Load sentence template embeddings."""
        embeddings = {}
        sentences = ["I can write", "I like apples", "We go home", "The cat runs"]
        
        for sentence in sentences:
            # Assume templates are in templates/sentences/{sentence_slug}/
            sentence_slug = sentence.lower().replace(" ", "_")
            template_dir = os.path.join(os.path.dirname(__file__), "templates", "sentences", sentence_slug)
            
            if os.path.exists(template_dir):
                template_files = [f for f in os.listdir(template_dir) if f.endswith('.png')]
                if template_files:
                    emb_list = []
                    for tf in template_files:
                        img_path = os.path.join(template_dir, tf)
                        img = Image.open(img_path).convert('RGB')
                        processed = self.clip_preprocess(img).unsqueeze(0)
                        with torch.no_grad():
                            emb = self.clip_model.encode_image(processed)
                            emb_list.append(emb.squeeze())
                    
                    embeddings[sentence] = torch.stack(emb_list).mean(dim=0)
        
        return embeddings

    def _cache_quality_embeddings(self) -> Dict[str, torch.Tensor]:
        """Cache quality assessment text embeddings."""
        quality_texts = [
            "well-formed handwriting",
            "neat handwriting", 
            "clear handwriting",
            "poor handwriting",
            "messy handwriting"
        ]
        
        embeddings = {}
        for text in quality_texts:
            tokens = open_clip.tokenize(text)
            with torch.no_grad():
                emb = self.clip_model.encode_text(tokens)
                embeddings[text] = emb.squeeze()
        
        return embeddings

    def predict(self, image: cog.Input[Image.Image], expected_character: cog.Input[str] = None, mode: cog.Input[str] = "alphabet") -> Dict:
        """Run handwriting recognition."""
        try:
            start_time = time.time()
            
            # Preprocess image
            processed_img = self.clip_preprocess(image).unsqueeze(0)
            
            # Get image embedding
            with torch.no_grad():
                img_embedding = self.clip_model.encode_image(processed_img).squeeze()
            
            if mode == "alphabet":
                return self._predict_alphabet(img_embedding, expected_character)
            elif mode == "number":
                return self._predict_number(img_embedding, expected_character)
            elif mode == "sentence":
                return self._predict_sentence(img_embedding, expected_character)
            else:
                return {"error": "Invalid mode. Use 'alphabet', 'number', or 'sentence'"}
                
        except Exception as e:
            logger.error(f"Prediction error: {e}")
            return {"error": str(e)}

    def _predict_alphabet(self, img_embedding: torch.Tensor, expected: str = None) -> Dict:
        """Predict for alphabet mode."""
        similarities = {}
        
        for char, emb in self.letter_embeddings.items():
            sim = (img_embedding @ emb).item()
            similarities[char] = sim
        
        # Find best match
        detected = max(similarities, key=similarities.get)
        confidence = similarities[detected] * 100
        
        # Quality score
        quality_similarities = {}
        for quality, emb in self.quality_embeddings.items():
            sim = (img_embedding @ emb).item()
            quality_similarities[quality] = sim
        
        quality_score = max(quality_similarities.values()) * 100
        
        # Is correct
        is_correct = False
        if expected:
            expected_sim = similarities.get(expected.upper(), 0)
            threshold = 0.75 if expected.islower() else 0.8
            is_correct = expected_sim >= threshold
        
        return {
            "detected_character": detected,
            "confidence": round(confidence, 1),
            "similarity_score": round(similarities[detected], 3),
            "quality_score": round(quality_score, 1),
            "is_correct": is_correct
        }

    def _predict_number(self, img_embedding: torch.Tensor, expected: str = None) -> Dict:
        """Predict for number mode."""
        similarities = {}
        
        for digit, emb in self.digit_embeddings.items():
            sim = (img_embedding @ emb).item()
            similarities[digit] = sim
        
        # Find best match
        detected = max(similarities, key=similarities.get)
        confidence = similarities[detected] * 100
        
        # Quality score (same as alphabet)
        quality_similarities = {}
        for quality, emb in self.quality_embeddings.items():
            sim = (img_embedding @ emb).item()
            quality_similarities[quality] = sim
        
        quality_score = max(quality_similarities.values()) * 100
        
        # Is correct
        is_correct = False
        if expected:
            expected_sim = similarities.get(expected, 0)
            threshold = 86.0 if expected == "6" else 80.0
            is_correct = expected_sim >= (threshold / 100)
        
        return {
            "detected_character": detected,
            "confidence": round(confidence, 1),
            "similarity_score": round(similarities[detected], 3),
            "quality_score": round(quality_score, 1),
            "is_correct": is_correct
        }

    def _predict_sentence(self, img_embedding: torch.Tensor, expected: str = None) -> Dict:
        """Predict for sentence mode."""
        similarities = {}
        
        for sentence, emb in self.sentence_embeddings.items():
            sim = (img_embedding @ emb).item()
            similarities[sentence] = sim
        
        # Find best match
        detected = max(similarities, key=similarities.get)
        confidence = similarities[detected] * 100
        
        # Quality score
        quality_similarities = {}
        for quality, emb in self.quality_embeddings.items():
            sim = (img_embedding @ emb).item()
            quality_similarities[quality] = sim
        
        quality_score = max(quality_similarities.values()) * 100
        
        # Is correct
        is_correct = False
        if expected and expected in similarities:
            expected_sim = similarities[expected]
            threshold = 0.85  # From sentence_routes
            is_correct = expected_sim >= threshold
        
        return {
            "detected_character": detected,
            "confidence": round(confidence, 1),
            "similarity_score": round(similarities[detected], 3),
            "quality_score": round(quality_score, 1),
            "is_correct": is_correct
        }